
module Diary
  module Query
    class Select
      def initialize(table, context=nil)
        @table_name = table
        @context = context
        @additions = []
      end

      def context
        @context
      end

      ## evaluation conditions, called when Select is given a context
      # FIXME: it's gross that Query::Select knows about Model

      def execute_in_context(sql)
        Diary.debug("[Query::Select execute_in_context] connection.execute(#{ sql.inspect })")
        if Array === sql
          context.connection.execute(*sql)
        else
          context.connection.execute(sql)
        end
      end

      def first
        return self unless context
        result = execute_in_context(self.limit(1).to_sql)
        context.materialize(result)[0]
      end

      def all
        return self unless context
        result = execute_in_context(self.to_sql)
        context.materialize(result)
      end

      def each(&block)
        return self unless context
        result = execute_in_context(self.to_sql)
        context.materialize(result).each(&block)
      end

      def map(&block)
        return self unless context
        result = execute_in_context(self.to_sql)
        context.materialize(result).map(&block)
      end

      def size
        return self unless context
        result = execute_in_context(self.to_sql)
        result.size
      end
      alias :count :size

      ##

      def select(column_query)
        @column_query = column_query
      end

      def exists?(*conditions)
        if conditions.size > 0
          @additions = []
          @additions << Where.new(*conditions)
          @additions << Limit.new(1)
        end
        c = self.count
        c && c > 0
      end

      def where(*conditions)
        # multiple wheres are OR'd
        @additions << Where.new(*conditions)
        self
      end

      def order(*conditions)
        @additions << Order.new(*conditions)
        self
      end

      def limit(*conditions)
        @additions << Limit.new(*conditions)
        self
      end

      def group_by(*conditions)
        @additions << GroupBy.new(*conditions)
        self
      end

      def to_sql
        # combine @additions in order: WHERE () GROUP BY () ORDER () LIMIT ()

        sql_string = []
        bind_vars = []

        wheres = @additions.select {|a| Where === a}
        group_bys = @additions.select {|a| GroupBy === a}
        orders = @additions.select {|a| Order === a}
        limits = @additions.select {|a| Limit === a}

        if wheres.size > 0
          sql_string << "WHERE"

          where_params = []

          wheres = wheres.each do |w|
            if w.has_bound_vars?
              bind_vars << w.prepared_statement.bind_vars
            end

            where_params << w.prepared_statement.sql_string
          end

          sql_string << where_params.map {|wp|
            "(#{ wp })"
          }.join(' OR ')
        end

        if group_bys.size > 0
          sql_string << "GROUP BY #{group_bys.map {|gb| gb.prepared_statement.sql_string}.join(', ')}"
        end

        if orders.size > 0
          sql_string << "ORDER BY #{orders.map {|ord| ord.prepared_statement.sql_string}.join(', ')}"
        end

        if limits.size > 0
          # only 1 allowed, last takes precedence
          limit = limits.last
          sql_string << "LIMIT #{limit.prepared_statement.sql_string}"
        end

        query = [
          "SELECT #{ @column_query || '*' }",
          "FROM `#{ @table_name }`",
          sql_string
        ].join(' ')

        # once to_sql is called, the Query is reset
        @additions = []

        # return sqlite compatible SQL
        returning = if bind_vars.size > 0
                      [query, bind_vars.flatten]
                    else
                      query
                    end
        returning
      end
    end

    class SQLBoundParams
      def initialize(left, right)
        @for_sql_query = [left, right]
      end

      def sql_string
        @for_sql_query[0]
      end

      def bind_vars
        @for_sql_query[1]
      end
    end

    class SQLString
      def initialize(value)
        @for_sql_query = value
      end

      def sql_string
        @for_sql_query
      end
    end

    class Node
      def string_or_symbol?(value)
        String === value || Symbol === value
      end

      def prepared_statement
        @sql_result
      end

      def has_bound_vars?
        SQLBoundParams === prepared_statement
      end
    end

    class Where < Node
      # convert conditions to AND'd list
      # returns either string or (string, bind_params) 2-tuple
      def initialize(*conditions)
        @sql_result = if Hash === conditions[0]
                        attrs = conditions[0]

                        keys = attrs.keys
                        vals = keys.map {|k| attrs[k]}

                        and_string = keys.map do |k|
                          if attrs[k].is_a?(Array)
                            bind_hold = attrs[k].map {|_| '?'}.join(',')
                            "`#{k}` in (#{bind_hold})"
                          else
                            "`#{k}` = ?"
                          end
                        end.join(' AND ')

                        # (string, bind)
                        SQLBoundParams.new(and_string, vals.flatten)
                      elsif conditions.size > 1 && String === conditions[0]
                        # assume (string, bind) given
                        SQLBoundParams.new(conditions[0], conditions[1..-1])
                      elsif conditions.size == 1 && String === conditions[0]
                        SQLString.new(conditions[0])
                      end
      end
    end

    class Order < Node
      def initialize(*conditions)
        sql_string = if conditions.size == 1
                       if string_or_symbol?(conditions[0])
                         conditions[0]
                       elsif Array === conditions[0]
                         conditions.join(', ')
                       else
                         conditions[0].to_s
                       end
                     elsif conditions.size > 1
                       conditions.join(', ')
                     end

        @sql_result = SQLString.new(sql_string)
      end
    end

    class Limit < Node
      def initialize(*conditions)
        sql_string = if conditions.size == 1
                       conditions[0]
                     elsif conditions.size > 1
                       conditions.join(', ')
                     end
        @sql_result = SQLString.new(sql_string)
      end
    end

    class GroupBy < Node
      def initialize(*conditions)
        sql_string = if conditions.size == 1
                       conditions[0]
                     elsif conditions.size > 1
                       conditions.join(', ')
                     end
        @sql_result = SQLString.new(sql_string)
      end
    end

    # class Table
    #   extend Select
    # end
  end
end
