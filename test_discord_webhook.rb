#!/usr/bin/env ruby

# Discord Webhook テスト用スクリプト
require 'httpclient'
require 'json'

# Discord Webhook URL
WEBHOOK_URL = 'https://canary.discord.com/api/webhooks/1410087393226260530/nzySCEfa_mr47mRkw_tlifMVDBmFdyqT97Wn8dSUsGgIdEFko-IxnH2_O8tPCfs3yQBV/slack'

# テスト用のメッセージを作成
def create_test_message
  # メイン通知メッセージ（担当者とウォッチャーのメンション付き）
  msg = "[テストプロジェクト] テストユーザー created <http://localhost:3000/issues/1|Issue #1: テストタスク>
@testuser1
@watcher1 @watcher2"

  # 添付ファイル（詳細情報）
  attachment = {
    text: "テスト用のタスクです。メンション機能と作業時間表示のテストを行います。",
    fields: [
      {
        title: "ステータス",
        value: "新規",
        short: true
      },
      {
        title: "優先度", 
        value: "通常",
        short: true
      },
      {
        title: "担当者",
        value: "テスト担当者",
        short: true
      },
      {
        title: "予定工数",
        value: "8.0時間",
        short: true
      },
      {
        title: "作業時間",
        value: "2.5時間", 
        short: true
      },
      {
        title: "ウォッチャー",
        value: "ウォッチャー1, ウォッチャー2",
        short: true
      }
    ]
  }

  {
    text: msg,
    link_names: 1,
    username: "Redmine",
    icon_url: "https://raw.github.com/sciyoshi/redmine-slack/gh-pages/icon.png",
    attachments: [attachment]
  }
end

# Discord Webhookにメッセージを送信
def send_to_discord(payload)
  begin
    client = HTTPClient.new
    client.ssl_config.cert_store.set_default_paths
    client.ssl_config.ssl_version = :auto
    
    puts "Sending test message to Discord..."
    puts "Payload: #{payload.to_json}"
    
    response = client.post(WEBHOOK_URL, 
      body: { payload: payload.to_json },
      header: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )
    
    puts "Response status: #{response.status}"
    puts "Response body: #{response.body}"
    
    if response.status == 204
      puts "✅ メッセージが正常に送信されました！"
    else
      puts "❌ エラー: #{response.status}"
    end
    
  rescue Exception => e
    puts "❌ 接続エラー: #{e.message}"
  end
end

# Issue更新時のテストメッセージも作成
def create_update_test_message
  msg = "[テストプロジェクト] 更新者 updated <http://localhost:3000/issues/1|Issue #1: テストタスク>
@testuser1
@watcher1 @watcher2"

  attachment = {
    text: "作業時間を追加しました。",
    fields: [
      {
        title: "ステータス",
        value: "進行中 ← 新規",
        short: false
      },
      {
        title: "作業時間",
        value: "5.0時間 ← 2.5時間",
        short: true
      }
    ]
  }

  {
    text: msg,
    link_names: 1,
    username: "Redmine",
    icon_url: "https://raw.github.com/sciyoshi/redmine-slack/gh-pages/icon.png",
    attachments: [attachment]
  }
end

# テスト実行
puts "=== Discord Webhook テスト開始 ==="
puts

puts "1. 新規Issue作成通知のテスト"
test_payload = create_test_message
send_to_discord(test_payload)

puts "\n" + "="*50 + "\n"

puts "2. Issue更新通知のテスト"
update_payload = create_update_test_message
send_to_discord(update_payload)

puts "\n=== テスト完了 ==="