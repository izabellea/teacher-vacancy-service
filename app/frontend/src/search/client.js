export const search = algoliasearch('QM2YE0HRBW', '20b88d28047d5e3d60437993ad3d9c50')

// TODO remove all this global scope
export const client = indexName => instantsearch({
    indexName: indexName,
    searchClient: search,
    searchFunction(helper) {
        if (helper.state.query) {
            helper.search();
        }
    },
})

export const index = indexName => search.initIndex(indexName)