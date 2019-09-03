# online_users.rb
#
# Author: Spencer Dixon <spencer@tuple.app>
# Copyright: Tuple, LLC 

query = ARGV[0]

# -------
# Utility 
# -------

def pbpaste
  `pbpaste`
end

def pbcopy(input)
 str = input.to_s
 IO.popen('pbcopy', 'w') { |f| f << str }
 str
end

def with_sandboxed_clipboard(&block)
  previous = pbpaste
  yield block
  pbcopy(previous)
end

def regex_fuzzy_search(query, list) 
  query_reg = /#{query.split('').join('.*?')}/
  sorted = []
  list.each do |string|
    match = query_reg.match string
    sorted << {string: string, rank: match.to_s.length} if match
  end
  sorted.sort_by! {|i| i[:rank] }
  sorted
end

# ----
# Main
# ----

with_sandboxed_clipboard do
  # -g to prevent Tuple from coming to foreground. We want Alfred to remain key.
  system('open -g tuple://online-users')

  online_users = pbpaste

  if online_users.include?(',') 
    users = online_users.split(',')
  else
    users = [online_users]
  end

  if query.length > 0 
    sorted = regex_fuzzy_search(query, users)
  else
    sorted = users
  end

  users_string = ""
  if users.count == 0
    users_string = "<item><title>No online users</title></item>"
  elsif sorted.count == 0
    users_string = "<item><title>Unable to find any matching online users</title></item>"
  else
    sorted.each do |user|
      users_string << %Q{<item arg="#{user[:string]}"><title>#{user[:string]}</title></item>}
    end
  end

  xml = <<EOS
<xml>
  <items>
    #{users_string}
  </items>
</xml>
EOS

  puts xml
end
