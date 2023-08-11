# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GodotGdErrorMonitorTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/monitor/GodotGdErrorMonitor.gd'


const error_report = """
	USER ERROR: this is an error
	   at: push_error (core/variant/variant_utility.cpp:880)
	"""
const script_error = """
	USER SCRIPT ERROR: Trying to call a function on a previously freed instance.
	   at: GdUnitScriptTypeTest.test_xx (res://addons/gdUnit4/test/GdUnitScriptTypeTest.gd:22)
"""


var _save_is_report_push_errors :bool
var _save_is_report_script_errors :bool


func before():
	_save_is_report_push_errors = GdUnitSettings.is_report_push_errors()
	_save_is_report_script_errors = GdUnitSettings.is_report_script_errors()
	# disable default error reporting for testing
	ProjectSettings.set_setting(GdUnitSettings.REPORT_PUSH_ERRORS, false)
	ProjectSettings.set_setting(GdUnitSettings.REPORT_SCRIPT_ERRORS, false)


func after():
	ProjectSettings.set_setting(GdUnitSettings.REPORT_PUSH_ERRORS, _save_is_report_push_errors)
	ProjectSettings.set_setting(GdUnitSettings.REPORT_SCRIPT_ERRORS, _save_is_report_script_errors)


func write_log(content :String) -> String:
	var log_file := create_temp_file("/test_logs/", "test.log")
	log_file.store_string(content)
	log_file.flush()
	return log_file.get_path_absolute()


func test_scan_for_push_errors() -> void:
	var log_file := write_log(error_report)
	var monitor := mock(GodotGdErrorMonitor, CALL_REAL_FUNC) as GodotGdErrorMonitor
	monitor._godot_log_file = log_file
	monitor._report_enabled = true
	
	# with disabled push_error reporting
	do_return(false).on(monitor)._is_report_push_errors()
	assert_array(monitor.reports()).is_empty()
	
	# with enabled push_error reporting
	do_return(true).on(monitor)._is_report_push_errors()

	var entry := ErrorLogEntry.new(ErrorLogEntry.TYPE.PUSH_ERROR, -1,
		"this is an error",
		"at: push_error (core/variant/variant_utility.cpp:880)")
	var expected_report := monitor._to_report(entry)
	assert_array(monitor.reports()).contains_exactly([expected_report])


func test_scan_for_script_errors() -> void:
	var log_file := write_log(script_error)
	var monitor := mock(GodotGdErrorMonitor, CALL_REAL_FUNC) as GodotGdErrorMonitor
	monitor._godot_log_file = log_file
	monitor._report_enabled = true
	
	# with disabled push_error reporting
	do_return(false).on(monitor)._is_report_script_errors()
	assert_array(monitor.reports()).is_empty()
	
	# with enabled push_error reporting
	do_return(true).on(monitor)._is_report_script_errors()
	
	var entry := ErrorLogEntry.new(ErrorLogEntry.TYPE.PUSH_ERROR, 22,
		"Trying to call a function on a previously freed instance.",
		"at: GdUnitScriptTypeTest.test_xx (res://addons/gdUnit4/test/GdUnitScriptTypeTest.gd:22)")
	var expected_report := monitor._to_report(entry)
	assert_array(monitor.reports()).contains_exactly([expected_report])


func test_custom_log_path() -> void:
	# save original log_path
	var log_path :String = ProjectSettings.get_setting("debug/file_logging/log_path")
	# set custom log path
	var custom_log_path := "user://logs/test-run.log"
	FileAccess.open(custom_log_path, FileAccess.WRITE).store_line("test-log")
	ProjectSettings.set_setting("debug/file_logging/log_path", custom_log_path)
	var monitor := GodotGdErrorMonitor.new()
	
	assert_that(monitor._godot_log_file).is_equal(custom_log_path)
	# restore orignal log_path
	ProjectSettings.set_setting("debug/file_logging/log_path", log_path)


func test_integration_test() -> void:
	var monitor := GodotGdErrorMonitor.new(true)
	# no errors reported
	monitor.start()
	monitor.stop()
	assert_array(monitor.reports()).is_empty()
	
	# push error
	monitor.start()
	push_error("Test GodotGdErrorMonitor 'push_error' reporting")
	push_warning("Test GodotGdErrorMonitor 'push_warning' reporting")
	monitor.stop()
	var reports := monitor.reports()
	assert_array(reports).has_size(2)
	if not reports.is_empty():
		assert_str(reports[0].message()).contains("Test GodotGdErrorMonitor 'push_error' reporting")
		assert_str(reports[1].message()).contains("Test GodotGdErrorMonitor 'push_warning' reporting")
	else:
		fail("Expect reporting runtime errors")
