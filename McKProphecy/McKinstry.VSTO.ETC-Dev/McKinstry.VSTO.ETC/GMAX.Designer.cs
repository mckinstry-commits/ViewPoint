﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.42000
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

#pragma warning disable 414
namespace McKinstry.ETC.Template {
    
    
    /// 
    [Microsoft.VisualStudio.Tools.Applications.Runtime.StartupObjectAttribute(1)]
    [global::System.Security.Permissions.PermissionSetAttribute(global::System.Security.Permissions.SecurityAction.Demand, Name="FullTrust")]
    public sealed partial class GMAX : Microsoft.Office.Tools.Excel.WorksheetBase {
        
        internal Microsoft.Office.Tools.Excel.NamedRange ActualStaffBurden;
        
        internal Microsoft.Office.Tools.Excel.NamedRange BandO;
        
        internal Microsoft.Office.Tools.Excel.NamedRange BaseFee;
        
        internal Microsoft.Office.Tools.Excel.NamedRange ContractActualFieldBurden;
        
        internal Microsoft.Office.Tools.Excel.NamedRange ContractShopBurden;
        
        internal Microsoft.Office.Tools.Excel.NamedRange GLI;
        
        internal Microsoft.Office.Tools.Excel.NamedRange SmallTools;
        
        internal Microsoft.Office.Tools.Excel.NamedRange Warranty;
        
        internal Microsoft.Office.Tools.Excel.NamedRange Bond;
        
        internal Microsoft.Office.Tools.Excel.NamedRange TB_Staff;
        
        internal Microsoft.Office.Tools.Excel.NamedRange TB_Field;
        
        internal Microsoft.Office.Tools.Excel.NamedRange TB_Shop;
        
        internal Microsoft.Office.Tools.Excel.NamedRange UF_Field;
        
        internal Microsoft.Office.Tools.Excel.NamedRange UF_Shop;
        
        internal Microsoft.Office.Tools.Excel.NamedRange ProjCost;
        
        internal Microsoft.Office.Tools.Excel.NamedRange ProjHours;
        
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        private global::System.Object missing = global::System.Type.Missing;
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        public GMAX(global::Microsoft.Office.Tools.Excel.Factory factory, global::System.IServiceProvider serviceProvider) : 
                base(factory, serviceProvider, "Sheet2", "Sheet2") {
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        protected override void Initialize() {
            base.Initialize();
            Globals.GMAX = this;
            global::System.Windows.Forms.Application.EnableVisualStyles();
            this.InitializeCachedData();
            this.InitializeControls();
            this.InitializeComponents();
            this.InitializeData();
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        protected override void FinishInitialization() {
            this.InternalStartup();
            this.OnStartup();
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        protected override void InitializeDataBindings() {
            this.BeginInitialization();
            this.BindToData();
            this.EndInitialization();
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        private void InitializeCachedData() {
            if ((this.DataHost == null)) {
                return;
            }
            if (this.DataHost.IsCacheInitialized) {
                this.DataHost.FillCachedData(this);
            }
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        private void InitializeData() {
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        private void BindToData() {
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
        private void StartCaching(string MemberName) {
            this.DataHost.StartCaching(this, MemberName);
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
        private void StopCaching(string MemberName) {
            this.DataHost.StopCaching(this, MemberName);
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
        private bool IsCached(string MemberName) {
            return this.DataHost.IsCached(this, MemberName);
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        private void BeginInitialization() {
            this.BeginInit();
            this.ActualStaffBurden.BeginInit();
            this.BandO.BeginInit();
            this.BaseFee.BeginInit();
            this.ContractActualFieldBurden.BeginInit();
            this.ContractShopBurden.BeginInit();
            this.GLI.BeginInit();
            this.SmallTools.BeginInit();
            this.Warranty.BeginInit();
            this.Bond.BeginInit();
            this.TB_Staff.BeginInit();
            this.TB_Field.BeginInit();
            this.TB_Shop.BeginInit();
            this.UF_Field.BeginInit();
            this.UF_Shop.BeginInit();
            this.ProjCost.BeginInit();
            this.ProjHours.BeginInit();
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        private void EndInitialization() {
            this.ProjHours.EndInit();
            this.ProjCost.EndInit();
            this.UF_Shop.EndInit();
            this.UF_Field.EndInit();
            this.TB_Shop.EndInit();
            this.TB_Field.EndInit();
            this.TB_Staff.EndInit();
            this.Bond.EndInit();
            this.Warranty.EndInit();
            this.SmallTools.EndInit();
            this.GLI.EndInit();
            this.ContractShopBurden.EndInit();
            this.ContractActualFieldBurden.EndInit();
            this.BaseFee.EndInit();
            this.BandO.EndInit();
            this.ActualStaffBurden.EndInit();
            this.EndInit();
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        private void InitializeControls() {
            this.ActualStaffBurden = Globals.Factory.CreateNamedRange(null, null, "ActualStaffBurden", "ActualStaffBurden", this);
            this.BandO = Globals.Factory.CreateNamedRange(null, null, "BandO", "BandO", this);
            this.BaseFee = Globals.Factory.CreateNamedRange(null, null, "BaseFee", "BaseFee", this);
            this.ContractActualFieldBurden = Globals.Factory.CreateNamedRange(null, null, "ContractActualFieldBurden", "ContractActualFieldBurden", this);
            this.ContractShopBurden = Globals.Factory.CreateNamedRange(null, null, "ContractShopBurden", "ContractShopBurden", this);
            this.GLI = Globals.Factory.CreateNamedRange(null, null, "GLI", "GLI", this);
            this.SmallTools = Globals.Factory.CreateNamedRange(null, null, "SmallTools", "SmallTools", this);
            this.Warranty = Globals.Factory.CreateNamedRange(null, null, "Warranty", "Warranty", this);
            this.Bond = Globals.Factory.CreateNamedRange(null, null, "Bond", "Bond", this);
            this.TB_Staff = Globals.Factory.CreateNamedRange(null, null, "TB_Staff", "TB_Staff", this);
            this.TB_Field = Globals.Factory.CreateNamedRange(null, null, "TB_Field", "TB_Field", this);
            this.TB_Shop = Globals.Factory.CreateNamedRange(null, null, "TB_Shop", "TB_Shop", this);
            this.UF_Field = Globals.Factory.CreateNamedRange(null, null, "UF_Field", "UF_Field", this);
            this.UF_Shop = Globals.Factory.CreateNamedRange(null, null, "UF_Shop", "UF_Shop", this);
            this.ProjCost = Globals.Factory.CreateNamedRange(null, null, "ProjCost", "ProjCost", this);
            this.ProjHours = Globals.Factory.CreateNamedRange(null, null, "ProjHours", "ProjHours", this);
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        private void InitializeComponents() {
            // 
            // ActualStaffBurden
            // 
            this.ActualStaffBurden.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // BandO
            // 
            this.BandO.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // BaseFee
            // 
            this.BaseFee.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // ContractActualFieldBurden
            // 
            this.ContractActualFieldBurden.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // ContractShopBurden
            // 
            this.ContractShopBurden.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // GLI
            // 
            this.GLI.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // SmallTools
            // 
            this.SmallTools.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // Warranty
            // 
            this.Warranty.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // Bond
            // 
            this.Bond.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // TB_Staff
            // 
            this.TB_Staff.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // TB_Field
            // 
            this.TB_Field.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // TB_Shop
            // 
            this.TB_Shop.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // UF_Field
            // 
            this.UF_Field.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // UF_Shop
            // 
            this.UF_Shop.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // ProjCost
            // 
            this.ProjCost.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // ProjHours
            // 
            this.ProjHours.DefaultDataSourceUpdateMode = System.Windows.Forms.DataSourceUpdateMode.Never;
            // 
            // GMAX
            // 
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
        private bool NeedsFill(string MemberName) {
            return this.DataHost.NeedsFill(this, MemberName);
        }
        
        /// 
        [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [global::System.CodeDom.Compiler.GeneratedCodeAttribute("Microsoft.VisualStudio.Tools.Office.ProgrammingModel.dll", "14.0.0.0")]
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Never)]
        protected override void OnShutdown() {
            this.ProjHours.Dispose();
            this.ProjCost.Dispose();
            this.UF_Shop.Dispose();
            this.UF_Field.Dispose();
            this.TB_Shop.Dispose();
            this.TB_Field.Dispose();
            this.TB_Staff.Dispose();
            this.Bond.Dispose();
            this.Warranty.Dispose();
            this.SmallTools.Dispose();
            this.GLI.Dispose();
            this.ContractShopBurden.Dispose();
            this.ContractActualFieldBurden.Dispose();
            this.BaseFee.Dispose();
            this.BandO.Dispose();
            this.ActualStaffBurden.Dispose();
            base.OnShutdown();
        }
    }
    
    internal sealed partial class Globals {
        
        private static GMAX _GMAX;
        
        internal static GMAX GMAX {
            get {
                return _GMAX;
            }
            set {
                if ((_GMAX == null)) {
                    _GMAX = value;
                }
                else {
                    throw new System.NotSupportedException();
                }
            }
        }
    }
}
