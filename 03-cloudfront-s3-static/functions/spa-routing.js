// CloudFront Function for SPA routing
// 將非 API 和非靜態資源的請求重寫為 /index.html，讓 Vue Router 處理路由

function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // 如果是 API 請求，不處理（讓它走 API Gateway）
    if (uri.startsWith('/api/')) {
        return request;
    }
    
    // 如果是根路徑，不處理
    if (uri === '/' || uri === '') {
        return request;
    }
    
    // 如果 URI 包含副檔名（靜態資源），不處理
    // 檢查常見的靜態資源副檔名
    var staticExtensions = [
        '.html', '.htm',
        '.js', '.jsx', '.mjs',
        '.css',
        '.json', '.xml',
        '.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp', '.ico',
        '.woff', '.woff2', '.ttf', '.eot',
        '.pdf', '.txt',
        '.map'
    ];
    
    var hasExtension = false;
    for (var i = 0; i < staticExtensions.length; i++) {
        if (uri.endsWith(staticExtensions[i])) {
            hasExtension = true;
            break;
        }
    }
    
    if (hasExtension) {
        return request;
    }
    
    // 其他情況（SPA 路由），重寫為 /index.html
    request.uri = '/index.html';
    return request;
}
