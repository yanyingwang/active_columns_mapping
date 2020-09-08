# active_columns_mapping
Let's say you have a db which was not written by rails, now you need to refactor it and build your new facy feature based on the db. But unfortunately, the table names and columns of this db is a mess and you can't just simply rename the columns since the old code is still running on this db.


Now with this gem, we can define a columns mapping ..... the rails imp the `attribute_alias`......

## usage
~~~ruby
class User < ApplicationRecord
  self.table_name = "ab_cd_users"
  self.columns_mapping = { "nickName" => "nick_name" }
end


u = User.first
u.nick_name
u.nick_name = "Yanying"
u.save
~~~


