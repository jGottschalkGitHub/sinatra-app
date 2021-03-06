before do
  if !%w[login signup].include?(request.path_info.split('/')[1]) && session[:user_id].nil? && !request.post?
    redirect '/login'
  end
  @user = current_user
end

helpers do
  def current_user
    @current_user ||= User.first(id: session[:user_id]) if session[:user_id]
  end
end

get '/new/?' do
  @list = List.new
  slim :new_list
end

get '/list/:id' do
  if session[:user_id].nil?
    redirect '/login'
  else
    @user = current_user
    list = List.first(id: params[:id])
    items = Item.where(list_id: params[:id]).order(Sequel.desc(:starred))
    slim :list_detail, locals: { list: list, items: items }
  end
end

get '/comment/delete/:id' do
  Comment.first(id: params[:id]).destroy
  flash.next[:success] = 'Comment has been deleted'
  redirect '/'
end

post '/new/?' do
  # create a list
  @user = current_user
  items = params[:items]
  @list = List.new_list params[:name], @user
  list_id = @list.id if @list.id
  if list_id
    if items
      items.each do |item|
        new_item = Item.new(name: item[:name], description: item[:description], list: @list, user: @user)
        new_item.save if new_item.valid?
        flash.next[:danger] = 'Item could not be created' if new_item.errors.any?
      end
    end
    flash.next[:success] = "List '#{@list.name}' has been created"
    redirect "/list/#{list_id}"
  else
    flash.now[:danger] = "List '#{@list.name}' could not be created"
    slim :new_list
  end
end

get '/edit/:id/?' do
  # check user permission and show the edit page
  @list = List.first(id: params[:id])
  @in_get = true
  can_edit = true
  if @list.nil?
    can_edit = false
  elsif @list.shared_with == 'public'
    user = current_user
    permission = Permission.first(list: @list, user: user)
    can_edit = false if permission.nil? || permission.permission_level == 'read_only'
  end

  if can_edit
    @items = Item.where(list_id: params[:id]).order(Sequel.desc(:starred))
    slim :editlist, locals: { list: @list, items: @items, newitems: [] }
  else
    slim :error, locals: { error: 'Invalid permissions' }
  end
end

post '/edit/?' do
  rerenderscript = false
  @in_get = false
  @listid = params[:id]
  @listname = params[:name]
  @list = List.first(id: @listid)
  # if rerenderscript = true we want the original items per list ordered by star
  @items = Item.where(list_id: params[:id]).order(Sequel.desc(:starred))
  user = current_user
  newitems = []
  @errors = {}
  @new_item_errors = {}
  newitems = params[:items_new] if params[:items_new]
  ### NEW ITEMS###
  if newitems
    newitems.each do |item|
      new_item = Item.new(name: item[:name], description: item[:description], list: @list, user: @user)
      new_item.save if new_item.valid?
      unless new_item.errors.empty?
        @new_item_errors = new_item.errors
        rerenderscript = true
      end
    end
  end
  # if submitting of new_items failed due error -> rerender and prefill with item values in slim
  if rerenderscript
    flash.now[:danger] = "List '#{@list.name}' could not be updated"
    slim :editlist, locals: { list: @list, items: @items, newitems: newitems }
  else
    ### EDIT EXISTING ITEMS ###
    return_value = List.edit_list @listid, @listname, params[:items], user
    @errors = return_value.errors if return_value.errors
    if !@errors.empty?
      flash.now[:danger] = "List '#{@list.name}' could not be updated"
      slim :editlist, locals: { list: @list, items: @items, newitems: newitems }
    else
      flash.next[:success] = "List '#{@list.name}' has been updated"
      redirect "/list/#{@listid}"
    end
  end
end
post '/comment/:id' do
  userid = current_user.id
  listid = params[:id].to_i
  lists = List.association_join(:permissions).where(user_id: userid)
  text = params[:comment].to_s
  comment = Comment.new(list_id: listid, user_id: userid, text: text, creation_date: Time.now)
  if comment.save
    flash.next[:success] = 'Comment has been created'
    redirect "/#{listid}"
  else
    flash.now[:danger] = 'Comment can not be empty'
    slim :list, locals: { lists: lists, list_modified_id: '' }
  end
end

get '/signup/?' do
  @user = User.new
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
    flash.next[:success] = 'User has been created'
    redirect '/dashboard'
  else
    flash.now[:danger] = 'User could not be created'
    slim :signup
  end
end

get '/login/?' do
  slim :login
end

get '/dashboard/starred' do
  # puts request.url
  # urlparts = request.url.split('/');
  # path = urlparts[-1]
  if current_user.nil?
    slim :login
  else
    user_id = current_user.id
    items = Item.where(user_id: user_id).where(starred: 1).order(Sequel.desc(:starred))
    slim :dashboard, locals: { items: items }
  end
end

get '/dashboard' do
  if current_user.nil?
    slim :login
  else
    user_id = current_user.id
    next_three_days = Time.now + 3 * 24 * 60 * 60
    items = Item.where(user_id: user_id).where { due_date < next_three_days }.order(Sequel.asc(:due_date))
    slim :dashboard, locals: { items: items }
  end
end

post '/login/?' do
  md5sum = Digest::MD5.hexdigest params[:password]
  @user = User.first(name: params[:name], password: md5sum)
  if @user.nil?
    slim :error, locals: { error: 'Invalid login credentials' }
  else
    session[:user_id] = @user.id
    redirect '/dashboard'
  end
end

get '/delete/:id/?' do
  id = params[:id]
  List.first(id: id).destroy
  flash.next[:success] = 'List has been deleted'
  redirect '/'
end

get '/logout/?' do
  session[:user_id] = nil
  slim :logged_out
end

# :id is optional since I want to pass in the id of a newly created 
# commentid here to scroll to the respective comment in DOM in list.slim
get '/(:id)?' do
  if session[:user_id].nil?
    slim :login
  else
    # all_lists =  List.all
    @user = current_user
    listid = !params[:id].nil? ? params[:id] : ''
    all_lists = List.association_join(:permissions).where(user_id: @user.id)
    slim :list, locals: { lists: all_lists, list_modified_id: listid }
  end
end
