#include <cpprest/http_client.h>
#include <cpprest/filestream.h>

using namespace utility;                    // 文字列変換などの一般的なユーティリティ
using namespace web;                        // URIのような共通の機能
using namespace web::http;                  // 共通のHTTP機能
using namespace web::http::client;          // HTTP クライアントの機能
using namespace concurrency::streams;       // 非同期ストリーム

pplx::task<void> PostTest()
{
    return pplx::create_task([] 
    {
        // クライアントの設定
        http_client client(L"https://httpbin.org/post");
        
        // 送信データの作成
        json::value postData;
        postData[L"message"] = json::value::string(L"Hello http");

        // リクエスト送信
        return client.request(methods::POST, L"", postData.serialize(), L"application/json");
    })
    
    .then([](http_response  response)
    {
        // ステータスコード判定
        if (response.status_code() == status_codes::OK)
        {
            // レスポンスボディを表示
            auto body = response.extract_string();
            std::wcout << body.get().c_str() << std::endl;
        }
    });
}


int main(void)
{
    try
    {
        PostTest().wait();
    }
    catch (const std::exception& e)
    {
        printf("Error exception:%s\n", e.what());
    }
    return 0;
}