Redmine::Plugin.register :tracker_management do
  name 'Tracker Management plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  	class TrackerManagementHookListener < Redmine::Hook::ViewListener
	 	# render_on :tracker_management_action_option, :partial => "common_section/tracker_action_option" 
		# render_on :view_welcome_index_right,:partial => "common_section/tracker_action_button"
		render_on :view_issues_sidebar_planning_bottom,:partial => "common_section/tracker_action_button"
		render_on :view_issue_sidebar_top,:partial => "common_section/subtask_action_button"
	 	render_on :view_issue_sidebar_issue_buttons, :partial => "common_section/tracker_action_option" 
	end

end
