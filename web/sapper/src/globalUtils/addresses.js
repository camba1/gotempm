// Prefix used on all goTemp service api requests
export let goTempePrefix = "goTemp.api."

export let productAddresses = {
    get: `${goTempePrefix}product/productSrv/GetProductById`,
    getAll: `${goTempePrefix}product/productSrv/GetProducts`,
    update: `${goTempePrefix}product/productSrv/UpdateProduct`,
    create: `${goTempePrefix}product/productSrv/CreateProduct`,
    delete: `${goTempePrefix}product/productSrv/DeleteProduct`,
    new: "/product/new",
    reload: "product/",
    previousPage: "/product",
    searchPreviousPage: "/"}

export let customerAddresses = {
    get: `${goTempePrefix}customer/customerSrv/GetCustomerById`,
    getAll: `${goTempePrefix}customer/customerSrv/GetCustomers`,
    update: `${goTempePrefix}customer/customerSrv/UpdateCustomer`,
    create: `${goTempePrefix}customer/customerSrv/CreateCustomer`,
    delete: `${goTempePrefix}customer/customerSrv/DeleteCustomer`,
    new: "/customer/new",
    reload: "customer/",
    previousPage: "/customer",
    searchPreviousPage: "/"}

export let userAddresses = {
    get: `${goTempePrefix}user/userSrv/GetUserById`,
    getAll: `${goTempePrefix}user/userSrv/GetUsers`,
    update: `${goTempePrefix}user/userSrv/UpdateUser`,
    create: `${goTempePrefix}user/userSrv/CreateUser`,
    delete: `${goTempePrefix}user/userSrv/DeleteUser`,
    new: "/user/new",
    reload: "user/",
    previousPage: "/user",
    searchPreviousPage: "/"}

export let promotionAddresses = {
    get: `${goTempePrefix}promotion/promotionSrv/GetPromotionById`,
    getAll: `${goTempePrefix}promotion/promotionSrv/GetPromotions`,
    update: `${goTempePrefix}promotion/promotionSrv/UpdatePromotion`,
    create: `${goTempePrefix}promotion/promotionSrv/CreatePromotion`,
    delete: `${goTempePrefix}promotion/promotionSrv/DeletePromotion`,
    new: "/promotion/new",
    reload: "promotion/",
    previousPage: "/promotion",
    searchPreviousPage: "/"}

export let authAddresses = {
    auth: `${goTempePrefix}user/userSrv/auth`,
    register: `${goTempePrefix}user/userSrv/CreateUser`,
    loginPage: "/login",
    previousPage: "/"
    }