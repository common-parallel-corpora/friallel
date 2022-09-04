
self.addEventListener("fetch", (event) => {
    // Let the browser do its default thing
    // for non-GET requests.
    if (event.request.method !== "GET") return;

    // Prevent the default, and handle the request ourselves.
    event.respondWith(
        (async () => {
            // Try to get the response from a cache.
            const cache = await caches.open("fs-v0001");
            const cachedResponse = await cache.match(event.request);

            if (cachedResponse) {
                // If we found a match in the cache, return it, but also
                // update the entry in the cache in the background.
                event.waitUntil(cache.add(event.request));
                return cachedResponse;
            }

            // If we didn't find a match in the cache, use the network.
            return fetch(event.request);
        })()
    );
});


const addResourcesToCache = async (resources) => {
    const cache = await caches.open("fs-v0001");
    await cache.addAll(resources);
};
  
self.addEventListener("install", (evt) => {
    console.log("Adding resources to cache...");
    evt.waitUntil(
        addResourcesToCache([
            "/",
            "/index.html",
            "/test-ablo.html",
        ])
    );
});