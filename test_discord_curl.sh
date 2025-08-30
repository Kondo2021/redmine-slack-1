#!/bin/bash

# Discord Webhook テスト用スクリプト（curl版）
WEBHOOK_URL="https://canary.discord.com/api/webhooks/1410087393226260530/nzySCEfa_mr47mRkw_tlifMVDBmFdyqT97Wn8dSUsGgIdEFko-IxnH2_O8tPCfs3yQBV/slack"

echo "=== Discord Webhook テスト開始 ==="
echo

echo "1. 新規Issue作成通知のテスト"
echo "送信中..."

# 新規Issue作成のテストペイロード
TEST_PAYLOAD='{
  "text": "[テストプロジェクト] テストユーザー created <http://localhost:3000/issues/1|Issue #1: テストタスク>\n@testuser1\n@watcher1 @watcher2",
  "link_names": 1,
  "username": "Redmine",
  "icon_url": "https://raw.github.com/sciyoshi/redmine-slack/gh-pages/icon.png",
  "attachments": [{
    "text": "テスト用のタスクです。メンション機能と作業時間表示のテストを行います。",
    "fields": [
      {
        "title": "ステータス",
        "value": "新規",
        "short": true
      },
      {
        "title": "優先度", 
        "value": "通常",
        "short": true
      },
      {
        "title": "担当者",
        "value": "テスト担当者",
        "short": true
      },
      {
        "title": "予定工数",
        "value": "8.0時間",
        "short": true
      },
      {
        "title": "作業時間",
        "value": "2.5時間", 
        "short": true
      },
      {
        "title": "ウォッチャー",
        "value": "ウォッチャー1, ウォッチャー2",
        "short": true
      }
    ]
  }]
}'

# Discord Webhookに送信
curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "payload=$TEST_PAYLOAD" \
  "$WEBHOOK_URL"

echo
echo "Response code: $?"

echo
echo "=================================================="
echo

echo "2. Issue更新通知のテスト"
echo "送信中..."

# Issue更新のテストペイロード  
UPDATE_PAYLOAD='{
  "text": "[テストプロジェクト] 更新者 updated <http://localhost:3000/issues/1|Issue #1: テストタスク>\n@testuser1\n@watcher1 @watcher2",
  "link_names": 1,
  "username": "Redmine",
  "icon_url": "https://raw.github.com/sciyoshi/redmine-slack/gh-pages/icon.png",
  "attachments": [{
    "text": "作業時間を追加しました。",
    "fields": [
      {
        "title": "ステータス",
        "value": "進行中 ← 新規",
        "short": false
      },
      {
        "title": "作業時間",
        "value": "5.0時間 ← 2.5時間",
        "short": true
      }
    ]
  }]
}'

curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "payload=$UPDATE_PAYLOAD" \
  "$WEBHOOK_URL"

echo
echo "Response code: $?"
echo
echo "=== テスト完了 ==="