class TrackerManagementActionsController < ApplicationController
	# before_action :check_user, only:[:show]
	require 'csv'    

	def index
		@projects = Project.select(:id,:name)
	end

	def tracker_log
		@@tracker_log ||= Logger.new("#{Rails.root}/log/tracker_bulk_upload.log")
	end

	# def show
	# 	# @projects = Project.select(:id,:name)
	# end

	# def new
	# 	@projects = Project.select(:id,:name)
	# 	@tracker_action = TrackerManagementAction.new()
	# end

	# def create
	# 	@projects = Project.select(:id,:name)
	# 	@tracker_action = TrackerManagementAction.new(tracker_action_params)
	# 	if @tracker_action.save
	# 		flash[:success] = "Action created successfuly!!"
	# 		redirect_to tracker_actions_path
	# 	else
	# 		@tracker_action.errors.full_messages.each{|a| flash[:errors] = a} 
	# 		render :new
	# 	end	
	# end

	def create_trecker
		@projects = Project.select(:id,:name)
		project_id = tracker_action_params['project_id']
		tracker_log.info("======> project id:  #{project_id} <=========")
		tracker_id = tracker_action_params['tracker_id']
		tracker_log.info("======> tracker id:  #{tracker_id} <=========")
		parent_id = tracker_action_params['parent_id']
		tracker_log.info("======> Parent issue id:  #{parent_id} <=========")
		@tracker = Tracker.find_by_id(tracker_id)
		tracker_log.info("======> Tracker:  #{@tracker} <=========")


		@errors = {message:[],column_missing:[],data_missing:[]}
		if params[:tracker_action][:file].present? && !project_id.blank? && !@tracker.nil?
			@users = User.select(:id,:firstname,:lastname,:login)
			@categories = IssueCategory.select(:id,:name)
			@priorities = IssuePriority.select(:id,:name)
			@issue_status = IssueStatus.select(:id,:name)

			tracker_log.info("======> Inside the CSV file functionality <=========")
			csv_text = File.read(params[:tracker_action][:file].path)
			csv = CSV.parse(csv_text, :headers => true, :header_converters=> lambda {|f| f.downcase.strip})
			
			custom_field_required = @tracker.custom_fields.blank? ? [] : @tracker.custom_fields.select(&:is_required).pluck(:name)
			tracker_log.info("======> custom_field_required:  #{custom_field_required} <=========")
			
			custom_field_names = @tracker.custom_fields.pluck(:name).reject(&:blank?)
			tracker_log.info("======> custom_field_names:  #{custom_field_names} <=========")
			# checking all required fields for creating issues
			(["subject", "status","priority",'author'] + custom_field_required.reject(&:blank?)).each{|name| @errors[:column_missing].push("required field #{name} is missing into CSV file") unless csv.headers.include?(name.downcase.strip()) }
			unless @errors[:column_missing].blank?
				tracker_log.info("======> missing columns error:  #{@errors[:column_missing]} <=========")
				render :index
				return
			end
			custom_fields_with_ids = {}
			
			custom_field_names.each do |name|
				tracker_log.info("======> custom_fields name:  #{name} <=========")
				custom_field = IssueCustomField.find_by_id(name) || IssueCustomField.find_by_name(name)
				unless custom_field.nil?
					custom_fields_with_ids[name] = {} 
					custom_fields_with_ids[name]['id'] = custom_field.id 
					custom_fields_with_ids[name]['default_options'] = custom_field.possible_values if ["list", "dependent_list"].include?(custom_field.field_format)
				end
			end
			
			tracker_log.info("======> custom_fields required data :  #{custom_fields_with_ids} <=========")
			
			data = []
			csv.each_with_index do |row,index|
				new_data = {}
				if row['subject'].blank? || row['status'].blank? || row['priority'].blank?
					@errors[:data_missing].push("\#Row #{index + 2 } has missing required field data")
				else
					issue_status = @issue_status.detect{|x| x.id.to_s == row['status'].downcase.strip || x.name.downcase.strip == row['status'].downcase.strip}
					tracker_log.info("======> issue_status :  #{issue_status} <=========")

					priority = @priorities.detect{|x| x.id.to_s == row['priority'].downcase.strip || x.name.downcase.strip == row['priority'].downcase.strip}
					tracker_log.info("======> priority:  #{priority} <=========")

					assignee = @users.detect{|x| x.id.to_s == row['author'].downcase.strip || x.firstname.downcase.strip == row['author'].downcase.strip || x.lastname.downcase.strip == row['author'].downcase.strip || "#{x.firstname} #{x.lastname}".downcase.strip == row['author'].downcase.strip || x.login.downcase.strip == row['author'].downcase.strip}
					tracker_log.info("======> assignee:  #{assignee} <=========")

					watchers = User.where(id: row['watcher']) || User.where(mail: row['watcher']) || User.where(firstname: row['watcher']) || User.select{|a| row['watcher'].include?(a.name) }
					tracker_log.info("======> watchers:  #{watchers} <=========")

					category = @categories.detect{|x| x.id.to_s == row['category'].downcase.strip || x.name.downcase.strip == row['category'].downcase.strip} 
					tracker_log.info("======> category:  #{category} <=========")

					author = @users.detect{|x| x.id.to_s == row['author'].downcase.strip || x.firstname.downcase.strip == row['author'].downcase.strip || x.lastname.downcase.strip == row['author'].downcase.strip || "#{x.firstname} #{x.lastname}".downcase.strip == row['author'].downcase.strip || x.login.downcase.strip == row['author'].downcase.strip}
					tracker_log.info("======> author:  #{author} <=========")

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
						custom_fields_with_ids.each do |key,value|

							tracker_log.info("======> custom field vales:  #{value} <=========")

							tracker_log.info("======> csv field vales:  #{row[key.downcase.strip]} <=========")

							tracker_log.info("======> custom field default_options:  #{value["default_options"] if value['default_options'].present?} <=========")

							new_input_value = value["default_options"].present? ?  (value["default_options"].detect{|a| a.downcase.strip == row[key.downcase.strip] }) : row[key.downcase.strip]

							tracker_log.info("======> custom value:  #{new_input_value} <=========")
							unless new_input_value.blank?
								new_data["custom_field_values"][value['id'].to_s] = new_input_value
							end
						end

						data.push(new_data)
						tracker_log.info("======> new data of \#Row #{index + 2 }:  #{new_data} <=========")
					else
						@errors[:message].push("\#Row #{index + 2 } priority field value doesn't exist in database") if priority.nil?
						@errors[:message].push("\#Row #{index + 2 } author field value doesn't exist in database") if author.nil?
						@errors[:message].push("\#Row #{index + 2 } status field value doesn't exist in database") if issue_status.nil?
					end
				end
			end
			if @errors[:message].blank? && @errors[:column_missing].blank? && @errors[:data_missing].blank?
				begin
					tracker_log.info("======> data to create:  #{data} <=========")
					@issues = Issue.create!(data)
					redirect_to issue_path(@issues.first.id) unless @issues.nil?
					# @issues.each_with_index do|a,i|
					# 	@index = (i + 2)
					# 	a.errors.full_messages.each{|msg|  @errors[:message].push("\#Row #{@index} value give error: #{msg}") unless a.errors.full_messages.blank? }
					# end
					# if @errors[:message].blank?
					# 	tracker_log.info("======> data to created successfuly <=========")
					# else
					# 	tracker_log.info("======> Error : #{@errors[:message]} <=========")
					# 	render :index
					# end
				rescue Exception => e
					tracker_log.info("======> This field value doesn't exist into Databse: #{e.message} <=========")
					@errors[:message].push("This field value doesn't exist into Databse: #{e.message}")
					render :index
				end
			else
				tracker_log.info("======> data Error Message:  #{@errors[:message]} <=========") unless @errors[:message].blank?
				tracker_log.info("======> required field missing error:  #{@errors[:column_missing]} <=========")
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
				# data_options = data_options.having("count(*) > 1") if params[:project_ids].size > 1

			when "custom_field"
				data_options = IssueCustomField.joins(:trackers).where(trackers: {id: params[:tracker_ids]}).select(:id,:name).group(:id,:name)
				# data_options = data_options.having("count(*) > 1") if params[:tracker_ids].size > 1
			when "tracker_tasks"
				data_options = Issue.joins(:tracker).where(tracker_id: params[:tracker_ids]).select(:id,:subject).group(:id,:subject)
				# data_options = data_options.having("count(*) > 1") if params[:tracker_ids].size > 1
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
