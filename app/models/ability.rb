class Ability
  include Hydra::Ability
  include Sufia::Ability

    def custom_permissions
      can :show_activity, User do |user|
        @current_user.id.present? && (admin? || user == @current_user)
      end
      cannot :destroy, ::GenericFile unless admin?
      # we blanket restrict downloading, and then whitelist appropriates cases
      cannot :download, GenericFile
      can :download, [GenericFile,SolrDocument] do |obj|
        # original logic in Hydra was user can download if user can read
        # here, we layer institutional access on top of that logic
        # we also want to be able to use the SolrDocument to check abilities to prevent performance hit
        if obj.institutional_access?
          @current_user.institutionally_authenticated? &&
          obj.read_groups.include?(@current_user.authenticating_institution)
        else
          can? :read, obj
        end
      end
      cannot :create, ::Collection 
      cannot :destroy, ::Collection unless admin?
      cannot [:edit, :update], ::Collection do |obj|
        obj.is_admin_set?
      end unless admin? 
      can :manage, :all if admin?
    end

    # modified from ability.rb in sufia-models, to force override
    def generic_file_abilities
      can :view_share_work, [GenericFile]
      can :create, [GenericFile] if registered_user?
      can :update_collections, GenericFile
    end

    # callback run at download time to check with CanCan whether or not the user
    # has download permissions on the file in question
    # overrides Hydra::Ability#download_permissions, which by default will
    # allow downloading if the user has read permissions on the object.
    # Per #582, we're splitting that up to allow restricting downloads to
    # institutional users
    #
    # download permissions are exercised in Hydra::Controller::DownloadBehavior
    def download_permissions
      can :download, ActiveFedora::File do |file|
        parent_uri = file.uri.to_s.sub(/\/[^\/]*$/, '')
        parent_id = ActiveFedora::Base.uri_to_id(parent_uri)
        can? :download, ActiveFedora::Base.find(parent_id)
      end
    end

    private

    def admin?
      user_groups.include? 'admin'
    end
end
