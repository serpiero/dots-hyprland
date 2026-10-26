.pragma library

function validUrl(value) {
    return /^https?:\/\/[^\s/?#]+[^\s]*$/.test(value) && value.indexOf("{query}") >= 0;
}
function engineList(options) {
    var entries = Array.from(options.webEngines || []).filter(function(engine) {
        return engine && typeof engine.name === "string" && typeof engine.keyword === "string"
            && /^[a-z0-9_-]+$/i.test(engine.keyword) && validUrl(engine.url || "");
    });
    if (entries.length) return entries;
    return [{ name: "Default", keyword: "default", url: (options.engineBaseUrl || "https://www.google.com/search?q=") + "{query}" }];
}
function resolve(text, options) {
    var query = String(text).trim();
    var prefix = options.prefix ? options.prefix.webSearch : "?";
    if (prefix && query.indexOf(prefix) === 0) query = query.slice(prefix.length).trim();
    var engines = engineList(options);
    var engine = engines.find(function(item) { return item.keyword === options.defaultWebEngine; }) || engines[0];
    var words = query.match(/^(\S+)\s+([\s\S]*)$/);
    if (words) {
        var requested = engines.find(function(item) { return item.keyword.toLowerCase() === words[1].toLowerCase(); });
        if (requested) { engine = requested; query = words[2].trim(); }
    }
    var exclusions = Array.from(options.excludedSites || []).filter(function(site) { return /^[a-z0-9.-]+$/i.test(site); });
    var terms = query + exclusions.map(function(site) { return " -site:" + site; }).join("");
    return {name: engine.name, query: query, url: engine.url.split("{query}").join(encodeURIComponent(terms))};
}
