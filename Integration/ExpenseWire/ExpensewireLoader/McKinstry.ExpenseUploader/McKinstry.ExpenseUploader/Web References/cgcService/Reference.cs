﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.296
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

// 
// This source code was auto-generated by Microsoft.VSDesigner, Version 4.0.30319.296.
// 
#pragma warning disable 1591

namespace McKinstry.ExpenseUploader.cgcService {
    using System;
    using System.Web.Services;
    using System.Diagnostics;
    using System.Web.Services.Protocols;
    using System.ComponentModel;
    using System.Xml.Serialization;
    using System.Data;
    
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.1")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Web.Services.WebServiceBindingAttribute(Name="UtilitySoap", Namespace="http://mckinstry.com/")]
    public partial class Utility : System.Web.Services.Protocols.SoapHttpClientProtocol {
        
        private System.Threading.SendOrPostCallback GetCGCDataByQueryOperationCompleted;
        
        private System.Threading.SendOrPostCallback addCGCDataByQueryOperationCompleted;
        
        private bool useDefaultCredentialsSetExplicitly;
        
        /// <remarks/>
        public Utility() {
            this.Url = global::McKinstry.ExpenseUploader.Properties.Settings.Default.McKinstry_ExpenseUploader_cgcService_Utility;
            if ((this.IsLocalFileSystemWebService(this.Url) == true)) {
                this.UseDefaultCredentials = true;
                this.useDefaultCredentialsSetExplicitly = false;
            }
            else {
                this.useDefaultCredentialsSetExplicitly = true;
            }
        }
        
        public new string Url {
            get {
                return base.Url;
            }
            set {
                if ((((this.IsLocalFileSystemWebService(base.Url) == true) 
                            && (this.useDefaultCredentialsSetExplicitly == false)) 
                            && (this.IsLocalFileSystemWebService(value) == false))) {
                    base.UseDefaultCredentials = false;
                }
                base.Url = value;
            }
        }
        
        public new bool UseDefaultCredentials {
            get {
                return base.UseDefaultCredentials;
            }
            set {
                base.UseDefaultCredentials = value;
                this.useDefaultCredentialsSetExplicitly = true;
            }
        }
        
        /// <remarks/>
        public event GetCGCDataByQueryCompletedEventHandler GetCGCDataByQueryCompleted;
        
        /// <remarks/>
        public event addCGCDataByQueryCompletedEventHandler addCGCDataByQueryCompleted;
        
        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://mckinstry.com/GetCGCDataByQuery", RequestNamespace="http://mckinstry.com/", ResponseNamespace="http://mckinstry.com/", Use=System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle=System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public System.Data.DataTable GetCGCDataByQuery(string queryString) {
            object[] results = this.Invoke("GetCGCDataByQuery", new object[] {
                        queryString});
            return ((System.Data.DataTable)(results[0]));
        }
        
        /// <remarks/>
        public void GetCGCDataByQueryAsync(string queryString) {
            this.GetCGCDataByQueryAsync(queryString, null);
        }
        
        /// <remarks/>
        public void GetCGCDataByQueryAsync(string queryString, object userState) {
            if ((this.GetCGCDataByQueryOperationCompleted == null)) {
                this.GetCGCDataByQueryOperationCompleted = new System.Threading.SendOrPostCallback(this.OnGetCGCDataByQueryOperationCompleted);
            }
            this.InvokeAsync("GetCGCDataByQuery", new object[] {
                        queryString}, this.GetCGCDataByQueryOperationCompleted, userState);
        }
        
        private void OnGetCGCDataByQueryOperationCompleted(object arg) {
            if ((this.GetCGCDataByQueryCompleted != null)) {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.GetCGCDataByQueryCompleted(this, new GetCGCDataByQueryCompletedEventArgs(invokeArgs.Results, invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }
        
        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://mckinstry.com/addCGCDataByQuery", RequestNamespace="http://mckinstry.com/", ResponseNamespace="http://mckinstry.com/", Use=System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle=System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public int addCGCDataByQuery(string queryString) {
            object[] results = this.Invoke("addCGCDataByQuery", new object[] {
                        queryString});
            return ((int)(results[0]));
        }
        
        /// <remarks/>
        public void addCGCDataByQueryAsync(string queryString) {
            this.addCGCDataByQueryAsync(queryString, null);
        }
        
        /// <remarks/>
        public void addCGCDataByQueryAsync(string queryString, object userState) {
            if ((this.addCGCDataByQueryOperationCompleted == null)) {
                this.addCGCDataByQueryOperationCompleted = new System.Threading.SendOrPostCallback(this.OnaddCGCDataByQueryOperationCompleted);
            }
            this.InvokeAsync("addCGCDataByQuery", new object[] {
                        queryString}, this.addCGCDataByQueryOperationCompleted, userState);
        }
        
        private void OnaddCGCDataByQueryOperationCompleted(object arg) {
            if ((this.addCGCDataByQueryCompleted != null)) {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.addCGCDataByQueryCompleted(this, new addCGCDataByQueryCompletedEventArgs(invokeArgs.Results, invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }
        
        /// <remarks/>
        public new void CancelAsync(object userState) {
            base.CancelAsync(userState);
        }
        
        private bool IsLocalFileSystemWebService(string url) {
            if (((url == null) 
                        || (url == string.Empty))) {
                return false;
            }
            System.Uri wsUri = new System.Uri(url);
            if (((wsUri.Port >= 1024) 
                        && (string.Compare(wsUri.Host, "localHost", System.StringComparison.OrdinalIgnoreCase) == 0))) {
                return true;
            }
            return false;
        }
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.1")]
    public delegate void GetCGCDataByQueryCompletedEventHandler(object sender, GetCGCDataByQueryCompletedEventArgs e);
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.1")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    public partial class GetCGCDataByQueryCompletedEventArgs : System.ComponentModel.AsyncCompletedEventArgs {
        
        private object[] results;
        
        internal GetCGCDataByQueryCompletedEventArgs(object[] results, System.Exception exception, bool cancelled, object userState) : 
                base(exception, cancelled, userState) {
            this.results = results;
        }
        
        /// <remarks/>
        public System.Data.DataTable Result {
            get {
                this.RaiseExceptionIfNecessary();
                return ((System.Data.DataTable)(this.results[0]));
            }
        }
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.1")]
    public delegate void addCGCDataByQueryCompletedEventHandler(object sender, addCGCDataByQueryCompletedEventArgs e);
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.1")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    public partial class addCGCDataByQueryCompletedEventArgs : System.ComponentModel.AsyncCompletedEventArgs {
        
        private object[] results;
        
        internal addCGCDataByQueryCompletedEventArgs(object[] results, System.Exception exception, bool cancelled, object userState) : 
                base(exception, cancelled, userState) {
            this.results = results;
        }
        
        /// <remarks/>
        public int Result {
            get {
                this.RaiseExceptionIfNecessary();
                return ((int)(this.results[0]));
            }
        }
    }
}

#pragma warning restore 1591