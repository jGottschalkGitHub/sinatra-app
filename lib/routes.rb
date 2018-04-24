
before do
  if !%w[login signup].include?(request.path_info.split('/')[1]) && session[:user_id].nil? && !request.post?
    redirect '/login'
  end
  @user = User.first(id: session[:user_id]) if session[:user_id]
end

get '/?' do
  if session[:user_id].nil?
    slim :error
  else
    # all_lists =  List.all
    @user = User.first(id: session[:user_id])
    all_lists = List.association_join(:permissions).where(user_id: @user.id)
    slim :list, locals: { list: all_lists }
  end
end

get '/list/:id' do
  if session[:user_id].nil?
    slim :error
  else
    # all_lists = List.all
    @user = User.first(id: session[:user_id])
    list = List.first(id: params[:id])
    items = Item.where(list_id: params[:id]).order(Sequel.desc(:starred))
    slim :list_detail, locals: { list: list, items: items }
  end
end

get '/comment/delete/:id' do
  Comment.first(id: params[:id]).destroy
  redirect 'http://localhost:4567/'
end

get '/new/?' do
  # show create list page
  @list = List.new
  slim :new_list
end

post '/new/?' do
  # create a list
  @user = User.first(id: session[:user_id])
  @list = List.new_list params[:name], params[:items], @user
  list_id = @list.id if @list.id
  if listID
    redirect "http://localhost:4567/list/#{list_id}"
  else
    slim :new_list
  end
end

get '/edit/:id/?' do
  # check user permission and show the edit page 
  @list = List.first(id: params[:id])
  @errors = []
  can_edit = true
  if @list.nil?
    can_edit = false

  elsif @list.shared_with == 'public'
    user = User.first(id: session[:user_id])
    permission = Permission.first(list: @list, user: user)
    if permission.nil? or permission.permission_level == 'read_only'
      can_edit = false
    end
  end

  if can_edit
    @items = Item.where(list_id: params[:id]).order(Sequel.desc(:starred))
    slim :edit_list, locals: { list: @list, items: @items, newitems: [] }
  else
    slim :error, locals: { error: 'Invalid permissions' }
  end
end

post '/edit/?' do
  rerenderscript = false
  @listid = params[:id]
  @listname = params[:name]
  @list = List.first(id: @listid)
  @items = Item.where(list_id: params[:id]).order(Sequel.desc(:starred))
  #items_id=params.select {|c| c.to_s =~ /^item/ }
  #items_desc=params.select{|c| c.to_s =~ /^description/ }
  userid = session[:user_id]
  user = User.first(id: session[:user_id])
  newitems = []
  @errors = []
  newitems = params[:items_new] if params[:items_new]
  @new_item_errors = {}
  if newitems
    newitems.each do |item|
      binding.pry
      new_item = Item.new(name: item[:name], description: item[:description], list: @list, user: @user)
      new_item.save if new_item.valid?
      unless new_item.errors.empty?
        @new_item_errors = new_item.errors
        rerenderscript = true
      end
    end
  end
  if rerenderscript
    slim :edit_list, locals: { list: @list, items: @items, newitems: newitems }
  else
    return_value = List.edit_list @listid, @listname, params[:items], user
    # if (defined?(return_value.items)) == 'local-variable'
    # if return_value.instance_of? List
    #  @items = return_value.items
    # elsif return_value.instance_of? Item
    #  @items = return_value
    # end
    @errors = return_value.errors if return_value.errors
    binding.pry
    if @errors.any?
      slim :edit_list, locals: { list: @list, items: @items, newitems: newitems }
    else
      redirect "http://localhost:4567/list/#{@listid}"
    end
  end
end

post '/comment/:id' do
  userid = User.first(id: session[:user_id]).id
  listid = params[:id].to_i
  text = params[:comment].to_s
  Comment.new_comment text, listid, userid
  redirect 'http://localhost:4567/'
end

post '/permission/?' do
  user = User.first(id: session[:user_id])
  list = List.first(id: params[:id])
  can_change_permission = true
  if list.nil?
    can_change_permission = false
  elsif list.shared_with != 'public'
    permission = Permission.first(list: list, user: user)
    if permission.nil? or permission.permission_level == 'read_only'
      can_change_permission = false
    end
  end
  if can_change_permission
    list.permission = params[:new_permissions]
    list.save
    current_permissions = Permission.first(list: list)
    permissions.each(&:destroy)
    current_permissions.each(&:destroy)
    if params[:new_permissions] == 'private' or parms[:new_permissions] == 'shared'
      user_perms.each do |perm|
        u = User.first(perm[:user])
        Permission.create(
          list: list,
          user: u,
          permission_level: perm[:level],
          created_at: Time.now,
          updated_at: Time.now
        )
      end
    end
    redirect request.referer
  else
    slim :error, locals: { error: 'Invalid permissions' }
  end
end

get '/signup/?' do
  @user = User.new #user will be empty but not nil -> so there will be no error in signup template when asking for @user
  if session[:user_id].nil?
    slim :signup
  else
    redirect '/logout'
  end
end

post '/signup/?' do
  md5sum = Digest::MD5.hexdigest params[:password]
  @user = User.new(name: params[:name], password: md5sum)
  if @user.save
    session[:user_id] = @user.id
    redirect '/login'
  else
    slim :signup
  end
end

get '/login/?' do
  if session[:user_id].nil?
    slim :login
  else
    slim :login
  end
end

post '/login/?' do
  md5sum = Digest::MD5.hexdigest params[:password]
  @user = User.first(name: params[:name], password: md5sum)
  if @user.nil?
    slim :error, locals: { error: 'Invalid login credentials' }
  else
    session[:user_id] = @user.id
    redirect '/'
  end
end

get '/delete/:id/?' do
  id = params[:id]
  #list = List.delete_list id
  #getting instance of List and calling destroy on it -> will activate destroy hook
  List.first(id: id).destroy
  redirect 'http://localhost:4567/'
end

get '/logout/?' do
  session[:user_id] = nil
  redirect '/login'
end
