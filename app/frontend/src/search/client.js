/* global algoliasearch instantsearch */

// This is the public API key which can be safely used in your frontend code.
// This key is usable for search queries and list the indices you've got access to.
export const search = algoliasearch('QM2YE0HRBW', '20b88d28047d5e3d60437993ad3d9c50');

export const searchClient = indexName => instantsearch({
    indexName: indexName,
    searchClient: search,
    searchFunction(helper) {
        if (helper.state.query) {
            helper.search();
        }
    },
});

export const index = indexName => search.initIndex(indexName);