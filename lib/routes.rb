
before do 
    if !['login', 'signup'].include?(request.path_info.split('/')[1]) && session[:user_id].nil? && !request.post?
        redirect '/login'
    end
    @user = User.first(id: session[:user_id]) if session[:user_id]
end


get '/?' do 
  
    if session[:user_id].nil?
        slim :error
    else
        all_lists =  List.all 
        @user = User.first(id: session[:user_id])
        all_lists = List.association_join(:permissions).where(user_id: @user.id)
        slim :list, locals: {list: all_lists}
    end
   
end


get '/list/:id' do 
  
    if session[:user_id].nil?
        slim :error
    else
        all_lists = List.all 
        @user = User.first(id: session[:user_id])
        @list = List.first(id: params[:id])
        slim :list_detail
    end
   
end


get '/comment/delete/:id' do
    commentId = params[:id]
    #Comment.delete_comment commentId
    comment = Comment.first(id: commentId).destroy
    redirect "http://localhost:4567/"
end

get '/new/?' do 
    # show create list page 
   
    slim :new_list
end 

post '/new/?' do
    # create a list
    @user = User.first(id: session[:user_id])
    list = List.new_list params[:name], params[:items], @user
    redirect "/"
end

get '/edit/:id/?' do 
    # check user permission and show the edit page 
    list = List.first(id: params[:id])    
   
    can_edit = true
    if list.nil?
        can_edit = false

    elsif list.shared_with == 'public'  
        user = User.first(id: session[:user_id])     
        permission = Permission.first(list: list, user: user)
        if permission.nil? or permission.permission_level == 'read_only'
            can_edit = false
        end
    end

    if can_edit
        items_sorted=list.items.sort_by{ |item| item[:starred] ? 0 : 1}
        #items_sorted = list.items_dataset.select_order_map(:checked).reverse
        #items_sorted = list.items_dataset.order(Sequel.desc(:starred))  
        slim :edit_list, locals: {list: list, items: items_sorted}
    else
        slim :error, locals: {error: 'Invalid permissions'}
    end
end 

post '/edit/?' do 

    listid = params[:id]
    listname = params[:name]
    #items_id=params.select {|c| c.to_s =~ /^item/ }
    #items_desc=params.select{|c| c.to_s =~ /^description/ }
    userid = session[:user_id]
    user = User.first(id: session[:user_id])
    List.edit_list listid, listname, params[:items], user
    redirect "http://localhost:4567/list/#{listid}"
end 

post '/update/?' do
    @user = User.first(id: session[:user_id])
    listname = params[:lists][0]['name']
    #list_name = List.get(:name)
    listid = params[:lists][0][:id].to_i
    list = List.edit_list list_id, list_name, params[:items], @user
    redirect "http://localhost:4567/list/#{listid}"
    #redirect request.referer
end

post '/comment/:id' do
    userid = User.first(id: session[:user_id]).id
    listid = params[:id].to_i
    text=params[:comment].to_s
    Comment.new_comment text, listid, userid
    redirect "http://localhost:4567/"
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
        current_permissions.each do |perm|
            perm.destroy
        end
    
        if params[:new_permissions] == 'private' or parms[:new_permissions] == 'shared'
            user_perms.each do |perm|
                u = User.first(perm[:user])
                Permission.create(
                    list: list, 
                    user: u, 
                    permission_level: perm[:level], 
                    created_at: Time.now, 
                    updated_at: Time.now)
            end
        end
    
        redirect request.referer
    else
        slim :error, locals: {error: 'Invalid permissions'}
    end
end 

get '/signup/?' do 

    if session[:user_id].nil?
        slim :signup
    else
        slim :error, locals: {error: 'Please log out first'}
    end 
end 

post '/signup/?' do
    md5sum = Digest::MD5.hexdigest params[:password]
    User.create(name: params[:name], password: md5sum)
    redirect '/login'
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
    user = User.first(name: params[:name], password: md5sum)
    if user.nil?
        
      slim :error, locals: {error: 'Invalid login credentials'}
    else
     
      session[:user_id] = user.id
      redirect '/'
    end
end

get '/delete/:id/?'do
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