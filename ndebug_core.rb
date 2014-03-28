class NdebugCore

	attr_accessor :break_info
	attr_accessor :watch_info

	# インスタンス初期化処理
	def initialize
		@break_info = BreakInfo.new
		@watch_info = WatcherInfo.new

		# スッテプ実行処理のフラグ
		@next_break_flag = false
	end

	def input_command(traceinfo)
		while true
			NdebugPrinter.print ">"
			# TODO : getsを置き換える
			input_command = DebugCommand.new(gets)
			break unless $ndebug.do_command(traceinfo, input_command)
		end
	end

	# ブレイク判断処理
	def is_break(traceinfo)

		# ステップ実行フラグを確認
		if @next_break_flag
			@next_break_flag = false
			return true
		end

		# ブレイクポイントチェック
		if break_info.check_break(traceinfo.file, traceinfo.line)
			return true
		end
	end

	# コマンド処理
	# falseを返却するとbreak解除
	def do_command(traceinfo, command)

		# 空文字であれば処理しない
		return true if command.is_empty

		# コマンド処理
		case command.command[0]
		when "ba" # break add
			return add_break_point(command)
		when "bd" # break delete
			return del_break_point(command)
		when "b"  # break list
			return show_break_list()
		when "wa" # watch add
			return add_watch_exp(command)
		when "wd" # watch delete
			return del_watch_exp(command)
		when "w"  # watch list
			return show_watch_list(traceinfo, command)
		when "+"  # next step
			return next_step()
		when "-"  # release step
			return release_step()
		when "e"  # eval command
			return do_eval(traceinfo, command)
		when "bo" # break point output setting
			return dump_break_list(command)
		when "bi" # break point input setting
			return load_break_list(command)
		when "wo" # watch list output setting
			return dump_watch_list(command)
		when "wi" # watch list input setting
			return load_watch_list(command)
		else
			NdebugPrinter.print "command not found\n"
			return true
		end
	end



	protected

	# ブレイクポイントの追加
	def add_break_point(command)
		unless command.command.count > 2
			NdebugPrinter.print "[command error] \"ba\" command is 2 parameters.(file and line)\n"
			return true
		end

		begin
			line_number = Integer(command.command[2])
		rescue
			NdebugPrinter.print "[command error] 2nd parameter is line number\n"
			return true
		end

		@break_info.add(command.command[1], line_number)
		NdebugPrinter.print sprintf("[add break point] %s(%s)\n", command.command[1], line_number)
		return true
	end

	# ブレイクポイントの削除
	def del_break_point(command)
		unless command.command.count > 1
			NdebugPrinter.print "[command error] \"bd\" command is 1 parameter.(index)\n"
			return true
		end

		
		if command.command[1] == "-a"
			# "-a" が指定されたら全削除
			while @break_info.list.count != 0
				@break_info.delete(0)
			end
		else
			# その他は指定された番号で削除を行う
			begin
				index_number = Integer(command.command[1])
			rescue
				NdebugPrinter.print "[command error] 1st parameter is index number or \"-a\"\n"
				return true
			end
			
			@break_info.delete(index_number)
		end
		NdebugPrinter.print sprintf("[delete break point]\n")
		return true
	end

	# ブレイクポイントの一覧表示
	def show_break_list()
		text = ""
		text << "----------break list----------\n"
		
		@break_info.list.each_with_index { |break_point, index|
			text << sprintf("%2d: %s(%s)\n", index, break_point.file, break_point.line)
		}
		
		text << "------------------------------\n"

		NdebugPrinter.print text
		return true
	end

	def add_watch_exp(command)
		unless command.command.count > 1
			NdebugPrinter.print "[command error] \"ba\" command is 1 parameter.(exp)\n"
			return true
		end

		@watch_info.add(command.command[1])
		NdebugPrinter.print "[add watch exp] #{command.command[1]}\n"
		return true
	end

	def del_watch_exp(command)
		unless command.command.count > 1
			NdebugPrinter.print "[command error] \"wd\" command is 1 parameter.(index)\n"
			return true
		end

		if command.command[1] == "-a"
			# "-a" が指定されたら全削除
			while @watch_info.list.count != 0
				@watch_info.delete(0)
			end
		else
			begin
				index_number = Integer(command.command[1])
			rescue
				NdebugPrinter.print "[command error] 1st parameter is index number or \"-a\"\n"
				return true
			end
			
			@watch_info.delete(index_number)
		end

		NdebugPrinter.print sprintf("[delete watch exp]\n")
		
		return true
	end

	# 作り途中
	def show_watch_list(traceinfo, command)
		text = ""
		text << "----------watch list----------\n"
		
		@watch_info.list.each_with_index { |watch_exp, index|

			watch_obj = nil
			watch_exp.split('.').each_with_index { |variable, count|
				if count == 0
					# 初回はスコープ元で名前解決
					watch_obj = eval("#{variable} rescue nil", traceinfo.binding)
				else
					# 配列アクセスであるかチェック
					temp_variable, array_index = split_array_word(variable)
					
					# 書式により参照方法が変わる
					case count_atmark(temp_variable)
					when 2 # クラス変数
						watch_obj = watch_obj.class_variable_get(temp_variable) rescue nil
					when 1 # インスタンス変数
						watch_obj = watch_obj.instance_variable_get(temp_variable) rescue nil
					else # その他
						watch_obj = watch_obj.method(temp_variable) rescue nil
					end

					# 配列アクセスを行う
					if array_index
						watch_obj = watch_obj[array_index]  rescue nil
					end
				end

				# nilであれば処理終了
				break if watch_obj.nil?
			}

			watch_obj = "NON!" unless watch_obj
			text << sprintf("%2d: [%s] : %s\n",index, watch_exp, watch_obj)
		}
		
		text << "------------------------------\n"

		NdebugPrinter.print text
		return true
	end

	# 次のステップへ
	def next_step()
		@next_break_flag = true
		return false
	end

	# ブレイク解除
	def release_step()
		NdebugPrinter.print "[release break]\n"
		return false
	end

	# コマンドを実行する
	def do_eval(traceinfo, command)
		eval_command = ""
		command.command.each_with_index {|word, index|
			next if index == 0
			eval_command << word
			eval_command << ' '
		}

		NdebugPrinter.print "[do eval] " + eval_command + "\n"
		eval(eval_command, traceinfo.binding) rescue NdebugPrinter.print($!.message + "\n")

		return true
	end

	# ブレイクポイントの一覧を出力する
	def dump_break_list(command)
		unless command.command.count > 1
			NdebugPrinter.print "[command error] \"bo\" command is 1 parameter.(dump file name)\n"
			return true
		end

		begin
			open(command.command[1], "w+") { |f|
				f.write @break_info.dump
				f.close
			}
			NdebugPrinter.print "[written break point file] \"#{command.command[1]}\"\n"
		rescue
			NdebugPrinter.print "[command error] #{$!.message}\n"
		end

		return true
	end

	# ブレイクポイントの一覧を読み込む
	def load_break_list(command)
		unless command.command.count > 1
			NdebugPrinter.print "[command error] \"bi\" command is 1 parameter.(dump file name)\n"
			return true
		end

		begin
			@break_info.load(open(command.command[1]).read)
			NdebugPrinter.print "[loaded break point file] \"#{command.command[1]}\"\n"
		rescue
			NdebugPrinter.print "[command error] #{$!.message}\n"
		end

		return true
	end

	# ウォッチ式の一覧を出力する
	def dump_watch_list(command)
		unless command.command.count > 1
			NdebugPrinter.print "[command error] \"wo\" command is 1 parameter.(dump file name)\n"
			return true
		end

		begin
			open(command.command[1], "w+") { |f|
				f.write @watch_info.dump
				f.close
			}
			NdebugPrinter.print "[written watch point file] \"#{command.command[1]}\"\n"
		rescue
			NdebugPrinter.print "[command error] #{$!.message}\n"
		end

		return true
	end

	# ウォッチ式の一覧を読み込む
	def load_watch_list(command)
		unless command.command.count > 1
			NdebugPrinter.print "[command error] \"wi\" command is 1 parameter.(dump file name)\n"
			return true
		end

		begin
			@watch_info.load(open(command.command[1]).read)
			NdebugPrinter.print "[loaded watch point file] \"#{command.command[1]}\"\n"
		rescue
			NdebugPrinter.print "[command error] #{$!.message}\n"
		end

		return true
	end

	private
	# 先頭文字の@のカウントを行う
	def count_atmark(variable)
		count = 0
		variable.split(//).each{|ch|
			if ch == '@'
				count += 1
			else
				break
			end
		}
		return count
	end

	# 配列アクセスの分割処理
	# 戻り値が配列で返す。受け取りは多重代入で受ける
	# 
	# 〜〜配列アクセスの場合〜
	# 第一戻り値：変数文字列
	# 第二戻り値：配列アクセスのインデックス
	# 
	# 〜〜配列アクセス以外の場合〜
	# 第一戻り値：変数文字列
	# 第二戻り値：nil
	def split_array_word(variable)
		# 配列内にアクセスできるようにする
		array_keyword_index = (/\[\d+\]/ =~ variable)
		if array_keyword_index
			array_variable = variable.slice(0, array_keyword_index)
			array_index = variable.slice(array_keyword_index + 1, variable.length - array_keyword_index - 2).to_i
			return array_variable, array_index
		else
			return variable, nil
		end
	end

end


# デバッグのメインクラス生成
$ndebug = NdebugCore.new


# デバッグ処理
set_trace_func proc { |event, file, line, id, binding, classname|

	# トレース情報をインスタンス化
	bind_obj = eval("instance_eval{|obj| obj}", binding)
	traceinfo = TraceInfo.new(event, file, line, id, binding, classname, bind_obj)

	# c-call, c-return は無視すべき？
	if $ndebug.is_break(traceinfo)

		# トレース情報の表示とコマンド取得
		traceinfo.print

		$ndebug.input_command(traceinfo)
	end
}
