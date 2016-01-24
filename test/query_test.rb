require 'test_helper'

class QueryTest < Minitest::Test
  def setup
    # db = setup_fixture_db
    @query = Diary::Query::Select.new('entries')
  end

  def assert_select_all(q)
    assert /SELECT \* FROM/ =~ q
  end

  def test_empty
    w = @query

    q = w.to_sql
    assert String === q
    assert(/SELECT \* FROM `entries`/ =~ q, "expected plain select * in #{ q }")
    assert_select_all(q)
  end

  def test_where
    w = @query

    # single conditional
    q = w.where(date_key: '2010').to_sql
    assert Array === q
    assert(/WHERE \(`date_key` = \?\)/ =~ q[0], "expected WHERE in #{ q[0] }")
    assert_select_all(q[0])

    # multiple conditional
    q = w.where(day: '2015', time: '09:00:00').to_sql
    assert(Array === q)
    assert(/WHERE \(`day` = \? AND `time` = \?\)/ =~ q[0], "expected WHERE in #{ q[0] }")
    assert_equal 2, q[1].size
    assert_select_all(q[0])

    # multiple wheres
    q = w.where(date_key: '2010').where(date_key: '2011').to_sql
    assert(Array === q)
    assert(/WHERE \([^)]+\) OR \([^)]+\)/ =~ q[0])
    assert_select_all(q[0])

    # string with literal
    q = w.where("1=1").to_sql
    assert(String === q)
    assert(/WHERE \(1=1\)/ =~ q, "expected WHERE in #{ q }")
    assert_select_all(q)

    # string with literal with bound vars
    q = w.where("date_key = ?", '2010', '2011').to_sql
    assert(Array === q)
    assert(/WHERE \(date_key = \?\)/ =~ q[0], "expected WHERE in #{ q[0] }")
    assert_equal 2, q[1].size
    assert_select_all(q[0])
  end

  def test_order
    w = @query

    w = Diary::Query::Select.new('entries')
    q = w.order('updated_at DESC').to_sql
    assert(String === q)
    assert(/updated_at DESC/ =~ q)
    assert_select_all(q)
  end

  def test_limit
    w = @query

    w = Diary::Query::Select.new('entries')
    q = w.limit(1).to_sql
    assert(String === q)
    assert(/LIMIT 1/ =~ q)
    assert_select_all(q)
  end

  def test_order_limit
    w = @query

    w = Diary::Query::Select.new('entries')
    q = w.order('updated_at DESC').limit(1).to_sql
    assert(String === q)
    assert(/ORDER BY updated_at DESC/ =~ q)
    assert(/LIMIT 1/ =~ q)
    assert_select_all(q)

    q = w.limit(1).order('updated_at DESC').to_sql
    assert(String === q)
    assert(/updated_at DESC/ =~ q)
    assert(/LIMIT 1/ =~ q)
    assert_select_all(q)
  end
end
