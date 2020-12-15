// Prefix used on all goTempM service api requests
export let goTempMePrefix = "goTempM.api."

export let productAddresses = {
    get: `${goTempMePrefix}product/productSrv/GetProductById`,
    getAll: `${goTempMePrefix}product/productSrv/GetProducts`,
    update: `${goTempMePrefix}product/productSrv/UpdateProduct`,
    create: `${goTempMePrefix}product/productSrv/CreateProduct`,
    delete: `${goTempMePrefix}product/productSrv/DeleteProduct`,
    new: "/product/new",
    reload: "product/",
    previousPage: "/product",
    searchPreviousPage: "/"}

export let customerAddresses = {
    get: `${goTempMePrefix}customer/customerSrv/GetCustomerById`,
    getAll: `${goTempMePrefix}customer/customerSrv/GetCustomers`,
    update: `${goTempMePrefix}customer/customerSrv/UpdateCustomer`,
    create: `${goTempMePrefix}customer/customerSrv/CreateCustomer`,
    delete: `${goTempMePrefix}customer/customerSrv/DeleteCustomer`,
    new: "/customer/new",
    reload: "customer/",
    previousPage: "/customer",
    searchPreviousPage: "/"}

export let userAddresses = {
    get: `${goTempMePrefix}user/userSrv/GetUserById`,
    getAll: `${goTempMePrefix}user/userSrv/GetUsers`,
    update: `${goTempMePrefix}user/userSrv/UpdateUser`,
    create: `${goTempMePrefix}user/userSrv/CreateUser`,
    delete: `${goTempMePrefix}user/userSrv/DeleteUser`,
    new: "/user/new",
    reload: "user/",
    previousPage: "/user",
    searchPreviousPage: "/"}

export let promotionAddresses = {
    get: `${goTempMePrefix}promotion/promotionSrv/GetPromotionById`,
    getAll: `${goTempMePrefix}promotion/promotionSrv/GetPromotions`,
    update: `${goTempMePrefix}promotion/promotionSrv/UpdatePromotion`,
    create: `${goTempMePrefix}promotion/promotionSrv/CreatePromotion`,
    delete: `${goTempMePrefix}promotion/promotionSrv/DeletePromotion`,
    new: "/promotion/new",
    reload: "promotion/",
    previousPage: "/promotion",
    searchPreviousPage: "/"}

export let authAddresses = {
    auth: `${goTempMePrefix}user/userSrv/auth`,
    register: `${goTempMePrefix}user/userSrv/CreateUser`,
    loginPage: "/login",
    previousPage: "/"
    }