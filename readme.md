# 📄 AI 伴侣系统 (后端 A) - API 使用文档 (V10)

**致“中间层”(Backend B) 团队：**

本文档定义了 AI 后端 (A) 提供的 API 接口。后端 A 是一个**无状态**服务，依赖调用方 (B) 传入所有必要的上下文（如 `story_truth` 和 `history`）。

## 1. 基础信息

* **服务基地址 (Base URL)：** `http://[后端A服务器IP]:5000`
* **开发环境 (单机)：** `http://localhost:5000`
* **内容格式 (Content-Type)：** 所有请求和响应均为 `application/json`。

## 2. 认证 (Authentication)

* **无需认证**。
* 服务 (A) 假定部署在 (B) 可以访问的受信任网络中。

## 3. 全局错误处理

当 AI 后端 (A) 内部发生错误时（例如，AI 模型调用失败、超时或返回了无效的 JSON），服务 (A) 将返回 `500 Internal Server Error` 状态码。

**关键：** 即使在 500 错误时，--

# 📄 AI 伴侣系统 (后端 A) - API 使用文档 (V10)

**致“中间层”(Backend B) 团队：**

本文档定义了 AI 后端 (A) 提供的 API 接口。后端 A 是一个**无状态**服务，依赖调用方 (B) 传入所有必要的上下文（如 `story_truth` 和 `history`）。

## 1. 基础信息

* **服务基地址 (Base URL)：** `http://[后端A服务器IP]:5000`
* **开发环境 (单机)：** `http://localhost:5000`
* **内容格式 (Content-Type)：** 所有请求和响应均为 `application/json`。

## 2. 认证 (Authentication)

* **无需认证**。
* 服务 (A) 假定部署在 (B) 可以访问的受信任网络中。

## 3. 全局错误处理

当 AI 后端 (A) 内部发生错误时（例如，AI 模型调用失败、超时或返回了无效的 JSON），服务 (A) 将返回 `500 Internal Server Error` 状态码。

**关键：** 即使在 500 错误时，响应体**仍然**会是一个包含错误信息的 JSON 对象。

**失败响应体 (`500 Internal Server Error`)**

```json
{
  "request_id": "req_a8f3-b1c9-4f7a-9a0e",
  "error": "AI service failed: [具体的错误信息]"
}
```

---

## 4. API 端点详情

### API 1: 循环提问 (The Q\&A Loop)

此接口用于游戏过程中的“提问-回答”循环。

* **端点：** \`POST /`POST /ai/judge_question`
* **职责：** 接收玩家的新问题，返回 AI 的“裁决”（是/否/不相关）和“评分”。

#### 请求体 (Request Body)

| 字段                          | 类型               | 必需 | 描述                           |
| :-------------------------- | :--------------- | :- | :--------------------------- |
| `request_id`                | `string`         | 是  | 唯一的请求 ID，将原样返回。              |
| \`story\_truth`story_truth` | `string`         | 是  | 完整的“汤底”真相。                   |
| `history`                   | `list[object]`   | 是  | **完整的**历史问答列表。如果刚开始，请传 `[]`。 |
| `history[].question`        | `string`         | -  | 历史中的问题。                      |
| `history[].answer`          | `string`         | -  | 历史中的回答。                      |
| `new_question`              | \`string`string` | 是  | 玩家本次提出的新问题。                  |

**请求示例 (`curl`)**

```bash
curl -X POST 'http://localhost:5000/ai/judge_question' \
-H 'Content-Type: application/json' \
-d '{
    "request_id": "req-12345",
    "story_truth": "一个男人和几个同伴乘坐热气球...",
    "history": [
        { "question": "他是独自一人吗？", "answer": "不是" }
    ],
    "new_question": "他是在天上吗？"
}'
```

#### 成功响应 (`200 OK`)

| 字段                                               | 类型        | 描述                                         |
| :----------------------------------------------- | :-------- | :----------------------------------------- |
| `request_id`                                     | `string`  | 同请求中的 \`request\_id`request_id`。           |
| `judge_answer`                                   | `string`  | AI 法官的裁决。固定为 `"是"`、`"否"` 或 \`"不`"不相关"` 之一。 |
| `score_result`                                   | `object`  | AI 计分员的评分结果。                               |
| \`score\_result.`score_result.score`             | `integer` | 0-3 的数字评分 (0=无关, 3=关键)。                    |
| \`score\_result.just`score_result.justification` | `string`  | AI 提供的简短评分理由。                              |

**成功响应示例**

```json
{
  "request_id": "req-12345",
  "judge_answer": "是",
  "score_result": {
    "score": 3,
    "justification": "这是一个关键问题，直接锁定了‘交通工具’这一核心要素。"
  }
}
```

---

### API 2: 提交最终答案 (The Answer)

此接口用于玩家提交他们猜测的“最终答案”，以结束游戏。

* **端点：** `POST /ai/validate_final_answer`
* **职责：** 接收玩家的最终答案，返回 AI 的“裁决”（是否正确）和“评语”。

#### 请求体 (Request Body)

| 字段                  | 类型       | 必需 | 描述               |
| :------------------ | :------- | :- | :--------------- |
| `request_id`        | `string` | 是  | 唯一的请求 ID，将原样返回。  |
| `story_truth`       | `string` | 是  | 完整的“汤底”真相。       |
| `final_answer_text` | `string` | 是  | 玩家提交的完整“最终答案”文本。 |

**请求示例 (`curl`)**

```bash
curl -X POST 'http://localhost:5000/ai/validate_final_answer' \
-H 'Content-Type: application/json' \
-d '{
    "request_id": "req-67890",
    "story_truth": "一个男人和几个同伴乘坐热气球...",
    "final_answer_text": "我猜到了！他们是在热气球上，为了减轻重量把抽签输了的人推下去了！"
}'
```

#### 成功响应 (`200 OK`)

| 字段                  | 类型       | 描述                                                                                                                          |
| :------------------ | :------- | :-------------------------------------------------------------------------------------------------------------------------- |
| `request_id`        | `string` | 同请求中的 \`request`request_id`。                                                                                                |
| `validation_status` | `string` | **\[关键]** AI 主裁的裁决状态。**固定为**以下三个值之一：<br>• `"CORRECT"` (完全正确)<br>• `"APPROACHING"` (接近了)<br>• \`"INCORRECT`"INCORRECT"` (不对) |
| `feedback`          | `string` | AI 提供的对玩家答案的简短评语。                                                                                                           |

\*\*成功响应示例**成功响应示例 (接近了)**

```json
{
  "request_id": "req-67890",
  "validation_status": "APPROACHING",
  "feedback": "你猜对了一半！他们确实在热气球上，但他们的问题不是重量..."
}
```

**成功响应示例 (正确)**

```json
{
  "request_id": "req-67890",
  "validation_status": "CORRECT",
  "feedback": "完全正确！恭喜你揭开了真相！"
}
```
