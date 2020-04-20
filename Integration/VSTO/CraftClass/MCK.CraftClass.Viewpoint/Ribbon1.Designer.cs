namespace MCK.CraftClass.Viewpoint
{
    partial class Ribbon1 : Microsoft.Office.Tools.Ribbon.RibbonBase
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        public Ribbon1()
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
            this.tab1 = this.Factory.CreateRibbonTab();
            this.grp = this.Factory.CreateRibbonGroup();
            this.btnCraftsToUpdate = this.Factory.CreateRibbonButton();
            this.btnCheckVariances = this.Factory.CreateRibbonButton();
            this.btnUpdate = this.Factory.CreateRibbonButton();
            this.btnShowPane = this.Factory.CreateRibbonButton();
            this.tab1.SuspendLayout();
            this.grp.SuspendLayout();
            this.SuspendLayout();
            // 
            // tab1
            // 
            this.tab1.ControlId.ControlIdType = Microsoft.Office.Tools.Ribbon.RibbonControlIdType.Office;
            this.tab1.Groups.Add(this.grp);
            this.tab1.Label = "McK";
            this.tab1.Name = "tab1";
            // 
            // grp
            // 
            this.grp.Items.Add(this.btnCraftsToUpdate);
            this.grp.Items.Add(this.btnCheckVariances);
            this.grp.Items.Add(this.btnUpdate);
            this.grp.Items.Add(this.btnShowPane);
            this.grp.Label = "Craft Class Updates";
            this.grp.Name = "grp";
            // 
            // btnCraftsToUpdate
            // 
            this.btnCraftsToUpdate.Label = "Crafts to be updated";
            this.btnCraftsToUpdate.Name = "btnCraftsToUpdate";
            this.btnCraftsToUpdate.OfficeImageId = "PivotTableLayoutReportLayout";
            this.btnCraftsToUpdate.ScreenTip = "Show a list of Crafts to be updated";
            this.btnCraftsToUpdate.ShowImage = true;
            this.btnCraftsToUpdate.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.btnCraftsToUpdate_Click);
            // 
            // btnCheckVariances
            // 
            this.btnCheckVariances.Label = "Check Variances";
            this.btnCheckVariances.Name = "btnCheckVariances";
            this.btnCheckVariances.OfficeImageId = "AccessTableTasks";
            this.btnCheckVariances.ScreenTip = "Check all rows irrespective of \'Load Y/N\' filter";
            this.btnCheckVariances.ShowImage = true;
            this.btnCheckVariances.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.btnCheckVariances_Click);
            // 
            // btnUpdate
            // 
            this.btnUpdate.Label = "Update Rates";
            this.btnUpdate.Name = "btnUpdate";
            this.btnUpdate.OfficeImageId = "ExportMoreMenu";
            this.btnUpdate.ShowImage = true;
            this.btnUpdate.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.btnUpdate_Click);
            // 
            // btnShowPane
            // 
            this.btnShowPane.Label = "Show Pane";
            this.btnShowPane.Name = "btnShowPane";
            this.btnShowPane.OfficeImageId = "DiagramReverseClassic";
            this.btnShowPane.ScreenTip = "Show action pane on left side";
            this.btnShowPane.ShowImage = true;
            this.btnShowPane.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.btnShowPane_Click);
            // 
            // Ribbon1
            // 
            this.Name = "Ribbon1";
            this.RibbonType = "Microsoft.Excel.Workbook";
            this.Tabs.Add(this.tab1);
            this.Load += new Microsoft.Office.Tools.Ribbon.RibbonUIEventHandler(this.Ribbon1_Load);
            this.tab1.ResumeLayout(false);
            this.tab1.PerformLayout();
            this.grp.ResumeLayout(false);
            this.grp.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        internal Microsoft.Office.Tools.Ribbon.RibbonTab tab1;
        internal Microsoft.Office.Tools.Ribbon.RibbonGroup grp;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton btnUpdate;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton btnCraftsToUpdate;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton btnCheckVariances;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton btnShowPane;
    }

    partial class ThisRibbonCollection
    {
        internal Ribbon1 Ribbon1
        {
            get { return this.GetRibbon<Ribbon1>(); }
        }
    }
}
