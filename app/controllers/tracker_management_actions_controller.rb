class TrackerManagementActionsController < ApplicationController
	# before_action :check_user, only:[:show]
	require 'csv'    

	def index
		@projects = Project.select(:id,:name)
	end

	def show
		# @projects = Project.select(:id,:name)
	end

	def new
		@projects = Project.select(:id,:name)
		@tracker_action = TrackerManagementAction.new()
	end

	def create
		@projects = Project.select(:id,:name)
		@tracker_action = TrackerManagementAction.new(tracker_action_params)
		if @tracker_action.save
			flash[:success] = "Action created successfuly!!"
			redirect_to tracker_actions_path
		else
			@tracker_action.errors.full_messages.each{|a| flash[:errors] = a} 
			render :new
		end	
	end

	def create_trecker
		@projects = Project.select(:id,:name)
		project_id = tracker_action_params['project_id']
		tracker_id = tracker_action_params['tracker_id']
		parent_id = tracker_action_params['parent_id']
		@tracker = Tracker.find_by_id(tracker_id)

		@errors = {message:[],column_missing:[],data_missing:[]}
		if params[:tracker_action][:file].present? && !project_id.blank? && !@tracker.nil?
			csv_text = File.read(params[:tracker_action][:file].path)
			csv = CSV.parse(csv_text, :headers => true, :header_converters=> lambda {|f| f.downcase.strip})
			custom_field_required = @tracker.custom_fields.blank? ? [] : @tracker.custom_fields.map{|a| a.name if a.is_required}
			custom_field_names = @tracker.custom_fields.map(&:name)

			# checking all required fields for creating issues
			(["subject", "status","priority",'author'] + custom_field_required).each{|name| @errors[:column_missing].push("required field #{name} is missing into CSV file") unless csv.headers.include?(name) }
			unless @errors[:column_missing].blank?
				render :index
				return
			end

			data = []
			csv.each_with_index do |row,index|
				new_data = {}
				if row['subject'].blank? || row['status'].blank? || row['priority'].blank?
					@errors[:data_missing].push("\#Row #{index + 2 } has missing required field data")
				else
					issue_status = IssueStatus.find_by_id(row['status']) ||  IssueStatus.find_by_name(row['status'])
					priority = IssuePriority.find_by_id(row['priority']) || IssuePriority.find_by_name(row['priority'])
					assignee = User.find_by_id(row['assignee']) || User.find_by_mail(row['assignee']) || User.find_by_firstname(row['assignee'])
					watchers = User.where(id: row['watcher']) || User.where(mail: row['watcher']) || User.where(firstname: row['watcher'])
					category = IssueCategory.find_by_id(row['category']) || IssueCategory.find_by_name(row['category'])
					author = User.find_by_id(row['author']) || User.find_by_mail(row['author']) || User.find_by_firstname(row['author'])
					if !priority.nil? && !issue_status.nil? && !author.nil?
						new_data['subject'] = row['subject']
						new_data['description'] = row['description']
						new_data['due_date'] = row['due_date'] unless row['due_date'].blank?
						new_data['category_id'] = category.id unless category.nil?
						new_data['status_id'] = issue_status.id
						new_data['assigned_to_id'] = assignee.id unless assignee.nil?
						new_data['priority_id'] = priority.id
						new_data['fixed_version_id'] = row['fixed_version_id']
						new_data['start_date'] = row['start_date'] unless row['start_date'].blank?
						new_data['done_ratio'] = row['done_ratio'] unless row['done_ratio'].blank?
						new_data['estimated_hours'] = row['estimated_hours'] unless row['estimated_hours'].blank?
						new_data['is_private'] = row['private'] unless row['private'].blank?
						new_data['project_id'] = project_id
						new_data['author_id'] = author.id
						new_data['parent_id'] = parent_id if parent_id.present?
						new_data['tracker_id'] = @tracker.id if @tracker.present?
						new_data['watcher_user_ids'] = watchers.map(&:id) if watchers.present?
						new_data["custom_field_values"]= {}
						custom_field_names.each do |name|
							issue_custom_field = IssueCustomField.find_by_id(name) || IssueCustomField.find_by_name(name) 
							new_data["custom_field_values"][issue_custom_field.id.to_s] = row[name] unless row[name].blank? || issue_custom_field.nil?
						end
						data.push(new_data)
					else
						@errors[:message].push("\#Row #{index + 2 } priority field value doesn't exist in database") if priority.nil?
						@errors[:message].push("\#Row #{index + 2 } author field value doesn't exist in database") if priority.nil?
						@errors[:message].push("\#Row #{index + 2 } status field value doesn't exist in database") if issue_status.nil?
					end
				end
			end
			if @errors[:message].blank? && @errors[:column_missing].blank? && @errors[:data_missing].blank?
				begin
					Issue.create!(data)
					redirect_to project_issues_path(project_id)
				rescue Exception => e
					@errors[:message].push("#{e.message}")
					render :index
				end
			else
				@errors[:column_missing].push("required field #{name} is missing") if project_id.blank?
				render :index
			end
		else
			render :index
		end
	end

	def options
		begin
			case params[:type]
			when "tracker"
				data_options = Tracker.joins(:projects).where(projects: {id: params[:project_ids]}).select(:id,:name).group(:id,:name)
				data_options = data_options.having("count(*) > 1") if params[:project_ids].size > 1

			when "custom_field"
				data_options = IssueCustomField.joins(:trackers).where(trackers: {id: params[:tracker_ids]}).select(:id,:name).group(:id,:name)
				data_options = data_options.having("count(*) > 1") if params[:tracker_ids].size > 1
			when "tracker_tasks"
				data_options = Issue.joins(:tracker).where(tracker_id: params[:tracker_ids]).select(:id,:subject).group(:id,:subject)
				data_options = data_options.having("count(*) > 1") if params[:tracker_ids].size > 1
				data_options = data_options.map{|a| {value: a.id, label: a.subject }}
			end
			render json: {options: data_options,type: params[:type]}
		rescue Exception => e
		end
	end

	private
	# def check_user
	# 	@user = User.find(params[:user_id])
	# 	redirect_to '/' unless @user.admin?
	# end

	def tracker_action_params
		params.require(:tracker_action).permit(:name,:project_id,:tracker_id,:parent_id,issue_custom_field_id:[],file:[])
	end
end
