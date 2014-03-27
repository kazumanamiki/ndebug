require "./util/printer"
require "./model/break_info"
require "./model/watcher_info"
require "./model/trace_info"
require "./model/debug_command"
require "./ndebug_core"

########################################################
# 設定等
########################################################
NdebugPrinter.instance.io = STDOUT # 出力先設定


########################################################
# 初回デバッグコマンド
########################################################
NdebugPrinter.print "hello! ndebug console.\n"
$ndebug.input_command(TraceInfo.new("", "ndebug.rb", 0, "", TOPLEVEL_BINDING, "", nil))
