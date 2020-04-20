namespace McKinstry.ViewPoint.ExcelAddIn
{
    partial class ViewPointExcelRibbon : Microsoft.Office.Tools.Ribbon.RibbonBase
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        public ViewPointExcelRibbon()
            : base(Globals.Factory.GetRibbonFactory())
        {
            InitializeComponent();
        }

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.tabViewPoint = this.Factory.CreateRibbonTab();
            this.gViewPointExecel = this.Factory.CreateRibbonGroup();
            this.bSyncRates = this.Factory.CreateRibbonButton();
            this.tabViewPoint.SuspendLayout();
            this.gViewPointExecel.SuspendLayout();
            // 
            // tabViewPoint
            // 
            this.tabViewPoint.ControlId.ControlIdType = Microsoft.Office.Tools.Ribbon.RibbonControlIdType.Office;
            this.tabViewPoint.Groups.Add(this.gViewPointExecel);
            this.tabViewPoint.Label = "ViewPoint";
            this.tabViewPoint.Name = "tabViewPoint";
            // 
            // gViewPointExecel
            // 
            this.gViewPointExecel.Items.Add(this.bSyncRates);
            this.gViewPointExecel.Label = "ViewPoint Operations";
            this.gViewPointExecel.Name = "gViewPointExecel";
            // 
            // bSyncRates
            // 
            this.bSyncRates.ControlSize = Microsoft.Office.Core.RibbonControlSize.RibbonControlSizeLarge;
            this.bSyncRates.Label = "Sync with ViewPoint";
            this.bSyncRates.Name = "bSyncRates";
            this.bSyncRates.ShowImage = true;
            this.bSyncRates.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.bSyncRates_Click);
            // 
            // ViewPointExcelRibbon
            // 
            this.Name = "ViewPointExcelRibbon";
            this.RibbonType = "Microsoft.Excel.Workbook";
            this.Tabs.Add(this.tabViewPoint);
            this.Load += new Microsoft.Office.Tools.Ribbon.RibbonUIEventHandler(this.ViewPointExcelRibbon_Load);
            this.tabViewPoint.ResumeLayout(false);
            this.tabViewPoint.PerformLayout();
            this.gViewPointExecel.ResumeLayout(false);
            this.gViewPointExecel.PerformLayout();

        }

        #endregion

        internal Microsoft.Office.Tools.Ribbon.RibbonTab tabViewPoint;
        internal Microsoft.Office.Tools.Ribbon.RibbonGroup gViewPointExecel;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton bSyncRates;
    }

    partial class ThisRibbonCollection
    {
        internal ViewPointExcelRibbon ViewPointExcelRibbon
        {
            get { return this.GetRibbon<ViewPointExcelRibbon>(); }
        }
    }
}
