#!/usr/bin/env ruby

# 実際のRedmine統合テスト用のモックスクリプト

# 既存のlistener.rbの動作をシミュレート
class MockIssue
  attr_accessor :id, :subject, :description, :status, :priority, :assigned_to, 
                :project, :author, :watcher_users, :estimated_hours, :spent_hours
  
  def initialize
    @id = 123
    @subject = "テスト用タスク - メンション機能の動作確認"
    @description = "この課題は@user1 さんに確認をお願いします。"
    @status = MockStatus.new("新規")
    @priority = MockPriority.new("通常")
    @assigned_to = MockUser.new("佐藤太郎", "sato.taro")
    @project = MockProject.new("テストプロジェクト")
    @author = MockUser.new("田中花子", "tanaka.hanako")
    @watcher_users = [
      MockUser.new("鈴木一郎", "suzuki.ichiro"),
      MockUser.new("山田次郎", "yamada.jiro")
    ]
    @estimated_hours = 8.5
    @spent_hours = 3.0
  end
  
  def to_s
    "Issue ##{@id}: #{@subject}"
  end
  
  def is_private?
    false
  end
end

class MockUser
  attr_accessor :name, :slack_username
  
  def initialize(name, slack_username = nil)
    @name = name
    @slack_username = slack_username
  end
  
  def to_s
    @name
  end
  
  def custom_value_for(field)
    return MockCustomValue.new(@slack_username) if @slack_username
    nil
  end
end

class MockCustomValue
  def initialize(value)
    @value = value
  end
  
  def value
    @value
  end
  
  def try(method)
    return @value if method == :value
    nil
  end
end

class MockProject
  def initialize(name)
    @name = name
  end
  
  def to_s
    @name
  end
end

class MockStatus
  def initialize(name)
    @name = name
  end
  
  def to_s
    @name
  end
end

class MockPriority
  def initialize(name)
    @name = name
  end
  
  def to_s
    @name
  end
end

# モック版の I18n
class MockI18n
  TRANSLATIONS = {
    "field_status" => "ステータス",
    "field_priority" => "優先度", 
    "field_assigned_to" => "担当者",
    "field_estimated_hours" => "予定工数",
    "field_spent_time" => "作業時間",
    "field_watcher" => "ウォッチャー"
  }
  
  def self.t(key)
    TRANSLATIONS[key] || key
  end
end

# Listenerクラスの主要メソッドを模倣
class TestListener
  def escape(msg)
    msg.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end
  
  def mentions(text)
    return nil if text.nil?
    names = extract_usernames(text)
    names.any? ? "\nTo: " + names.join(', ') : nil
  end
  
  def extract_usernames(text = '')
    return [] if text.nil?
    text.scan(/@[a-z0-9][a-z0-9_\-\.]*/).uniq
  end
  
  def assignee_mention(issue)
    return nil unless issue.assigned_to
    slack_username = get_slack_username(issue.assigned_to)
    return nil unless slack_username
    "\n@#{slack_username}"
  end

  def watchers_mention(issue)
    return nil unless issue.watcher_users.any?
    watcher_mentions = issue.watcher_users.map do |watcher|
      slack_username = get_slack_username(watcher)
      "@#{slack_username}" if slack_username
    end.compact
    return nil if watcher_mentions.empty?
    "\n#{watcher_mentions.join(' ')}"
  end

  def get_slack_username(user)
    return nil unless user
    slack_username = user.custom_value_for(nil).try(:value) if user.respond_to?(:custom_value_for)
    return nil if !slack_username || slack_username.to_s.strip.empty?
    slack_username.gsub('@', '')
  end
  
  def generate_message_and_attachment(issue)
    # メインメッセージ作成
    msg = "[#{escape issue.project}] #{escape issue.author} created <http://localhost:3000/issues/#{issue.id}|#{escape issue}>#{mentions issue.description}#{assignee_mention issue}#{watchers_mention issue}"
    
    # 添付ファイル（詳細情報）作成
    attachment = {}
    attachment[:text] = escape issue.description if issue.description
    attachment[:fields] = [
      {
        title: MockI18n.t("field_status"),
        value: escape(issue.status.to_s),
        short: true
      },
      {
        title: MockI18n.t("field_priority"),
        value: escape(issue.priority.to_s),
        short: true
      },
      {
        title: MockI18n.t("field_assigned_to"),
        value: escape(issue.assigned_to.to_s),
        short: true
      }
    ]

    if issue.estimated_hours
      attachment[:fields] << {
        title: MockI18n.t("field_estimated_hours"),
        value: escape("#{issue.estimated_hours}時間"),
        short: true
      }
    end

    if issue.spent_hours && issue.spent_hours > 0
      attachment[:fields] << {
        title: MockI18n.t("field_spent_time"),
        value: escape("#{issue.spent_hours}時間"),
        short: true
      }
    end
    
    attachment[:fields] << {
      title: MockI18n.t("field_watcher"),
      value: escape(issue.watcher_users.join(', ')),
      short: true
    }
    
    [msg, attachment]
  end
end

# テスト実行
puts "=== Redmine統合テスト（実際の実装版） ==="
puts

# テスト用のデータを作成
issue = MockIssue.new
listener = TestListener.new

puts "テスト用Issue情報:"
puts "  ID: #{issue.id}"
puts "  件名: #{issue.subject}"
puts "  説明: #{issue.description}"
puts "  担当者: #{issue.assigned_to} (Slack: #{issue.assigned_to.slack_username})"
puts "  ウォッチャー: #{issue.watcher_users.map{|w| "#{w} (Slack: #{w.slack_username})"}.join(', ')}"
puts "  予定工数: #{issue.estimated_hours}時間"
puts "  作業時間: #{issue.spent_hours}時間"
puts

puts "生成されるメッセージ:"
msg, attachment = listener.generate_message_and_attachment(issue)
puts "メイン: #{msg}"
puts
puts "添付ファイル:"
puts "  テキスト: #{attachment[:text]}"
puts "  フィールド:"
attachment[:fields].each_with_index do |field, i|
  puts "    #{i+1}. #{field[:title]}: #{field[:value]} (short: #{field[:short]})"
end

puts
puts "=== テスト完了 ==="