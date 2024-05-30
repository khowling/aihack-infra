
const PRICE_URL = 'https://prices.azure.com/api/retail/prices?currencyCode=\'EUR\'&$filter=serviceName eq \'Virtual Machines\' and armRegionName eq \'westeurope\' and priceType eq \'Consumption\' and contains(meterName, \'Spot\') eq false and contains(meterName, \'Low Priority\') eq false and contains(productName, \'Windows\') eq false'
const SKUS_LESS_THAN_EUR_PER_HOUR = 1


const getSKUs = async (url, limit, items) => {
    const res = await fetch(url);
    if(res.ok){
        const data = await res.json();
        console.log (`got ${data.Items.length} new items`)
        let resItems = [...items, ...(data.Items.filter(i => i.retailPrice < limit).map(i => { return  {retailPrice: i.retailPrice, armSkuName: i.armSkuName}}))];

        
        if (data.NextPageLink) {
            console.log (`calling next page`)
            return await getSKUs(data.NextPageLink, limit, resItems);
        } else {
            return resItems
        }
        
        
    }
}


getSKUs(PRICE_URL, SKUS_LESS_THAN_EUR_PER_HOUR, []).then(r => {
    // view the retailPrice and armSku
    //console.log(r)
    //console.log (r.sort((a, b) => b.retailPrice - a.retailPrice))

    // use this output to paste into the policy
    console.log(r.sort((a, b) => a.retailPrice - b.retailPrice).map(i => `'${i.armSkuName}'`).join('\n'))
})
