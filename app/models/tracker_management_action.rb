class TrackerManagementAction < ActiveRecord::Base
	validates :name, :project_id,presence: true
	serialize :project_id, Array
	serialize :tracker_id, Array
	serialize :issue_custom_field_id, Array

	def projects
		Project.where(id: self.project_id)
	end

	def trackers
		Tracker.where(id: self.tracker_id)
	end

	def issue_custom_fields
		IssueCustomField.where(id: self.issue_custom_field_id)
	end

	def project_names; projects.map(&:name).join(', ') end
	def tracker_names; trackers.map(&:name).join(', ') end
	def issue_custom_field_names; issue_custom_fields.map(&:name).join(', ') end
end
