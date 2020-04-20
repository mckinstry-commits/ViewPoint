namespace McKinstry.ViewPoint.Subcontract
{
    partial class SubcontractRibbon : Microsoft.Office.Tools.Ribbon.RibbonBase
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        public SubcontractRibbon()
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
            this.ViewPointTab = this.Factory.CreateRibbonTab();
            this.ContractsGroup = this.Factory.CreateRibbonGroup();
            this.bSubContracts = this.Factory.CreateRibbonButton();
            this.separator1 = this.Factory.CreateRibbonSeparator();
            this.bSample = this.Factory.CreateRibbonButton();
            this.separator3 = this.Factory.CreateRibbonSeparator();
            this.bChangeOrder = this.Factory.CreateRibbonButton();
            this.separator2 = this.Factory.CreateRibbonSeparator();
            this.bMasterContract = this.Factory.CreateRibbonButton();
            this.bSubOrder = this.Factory.CreateRibbonButton();
            this.separator4 = this.Factory.CreateRibbonSeparator();
            this.ViewPointTab.SuspendLayout();
            this.ContractsGroup.SuspendLayout();
            // 
            // ViewPointTab
            // 
            this.ViewPointTab.Groups.Add(this.ContractsGroup);
            this.ViewPointTab.Label = "ViewPoint";
            this.ViewPointTab.Name = "ViewPointTab";
            // 
            // ContractsGroup
            // 
            this.ContractsGroup.Items.Add(this.bSubContracts);
            this.ContractsGroup.Items.Add(this.separator1);
            this.ContractsGroup.Items.Add(this.bSample);
            this.ContractsGroup.Items.Add(this.separator3);
            this.ContractsGroup.Items.Add(this.bChangeOrder);
            this.ContractsGroup.Items.Add(this.separator2);
            this.ContractsGroup.Items.Add(this.bMasterContract);
            this.ContractsGroup.Items.Add(this.separator4);
            this.ContractsGroup.Items.Add(this.bSubOrder);
            this.ContractsGroup.Label = "Templates";
            this.ContractsGroup.Name = "ContractsGroup";
            // 
            // bSubContracts
            // 
            this.bSubContracts.ControlSize = Microsoft.Office.Core.RibbonControlSize.RibbonControlSizeLarge;
            this.bSubContracts.Image = global::McKinstry.ViewPoint.Subcontract.Properties.Resources.Subcontract;
            this.bSubContracts.Label = "Subcontract";
            this.bSubContracts.Name = "bSubContracts";
            this.bSubContracts.ShowImage = true;
            this.bSubContracts.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.bSubContracts_Click);
            // 
            // separator1
            // 
            this.separator1.Name = "separator1";
            // 
            // bSample
            // 
            this.bSample.ControlSize = Microsoft.Office.Core.RibbonControlSize.RibbonControlSizeLarge;
            this.bSample.Image = global::McKinstry.ViewPoint.Subcontract.Properties.Resources.Subcontract;
            this.bSample.Label = "Sample Subcontract";
            this.bSample.Name = "bSample";
            this.bSample.ShowImage = true;
            this.bSample.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.bSample_Click);
            // 
            // separator3
            // 
            this.separator3.Name = "separator3";
            // 
            // bChangeOrder
            // 
            this.bChangeOrder.ControlSize = Microsoft.Office.Core.RibbonControlSize.RibbonControlSizeLarge;
            this.bChangeOrder.Image = global::McKinstry.ViewPoint.Subcontract.Properties.Resources.Subcontract;
            this.bChangeOrder.Label = "Subcontract Change Order";
            this.bChangeOrder.Name = "bChangeOrder";
            this.bChangeOrder.ShowImage = true;
            this.bChangeOrder.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.bChangeOrder_Click);
            // 
            // separator2
            // 
            this.separator2.Name = "separator2";
            // 
            // bMasterContract
            // 
            this.bMasterContract.ControlSize = Microsoft.Office.Core.RibbonControlSize.RibbonControlSizeLarge;
            this.bMasterContract.Image = global::McKinstry.ViewPoint.Subcontract.Properties.Resources.Subcontract;
            this.bMasterContract.Label = "Master Contract";
            this.bMasterContract.Name = "bMasterContract";
            this.bMasterContract.ShowImage = true;
            this.bMasterContract.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.bMasterContract_Click);
            // 
            // bSubOrder
            // 
            this.bSubOrder.ControlSize = Microsoft.Office.Core.RibbonControlSize.RibbonControlSizeLarge;
            this.bSubOrder.Image = global::McKinstry.ViewPoint.Subcontract.Properties.Resources.Subcontract;
            this.bSubOrder.Label = "Master Subcontract  Order";
            this.bSubOrder.Name = "bSubOrder";
            this.bSubOrder.ShowImage = true;
            this.bSubOrder.Click += new Microsoft.Office.Tools.Ribbon.RibbonControlEventHandler(this.bSubOrder_Click);
            // 
            // separator4
            // 
            this.separator4.Name = "separator4";
            // 
            // SubcontractRibbon
            // 
            this.Name = "SubcontractRibbon";
            this.RibbonType = "Microsoft.Word.Document";
            this.Tabs.Add(this.ViewPointTab);
            this.Load += new Microsoft.Office.Tools.Ribbon.RibbonUIEventHandler(this.SubcontractRibbon_Load);
            this.ViewPointTab.ResumeLayout(false);
            this.ViewPointTab.PerformLayout();
            this.ContractsGroup.ResumeLayout(false);
            this.ContractsGroup.PerformLayout();

        }

        #endregion

        internal Microsoft.Office.Tools.Ribbon.RibbonTab ViewPointTab;
        internal Microsoft.Office.Tools.Ribbon.RibbonGroup ContractsGroup;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton bSubContracts;
        internal Microsoft.Office.Tools.Ribbon.RibbonSeparator separator1;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton bMasterContract;
        internal Microsoft.Office.Tools.Ribbon.RibbonSeparator separator2;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton bChangeOrder;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton bSample;
        internal Microsoft.Office.Tools.Ribbon.RibbonSeparator separator3;
        internal Microsoft.Office.Tools.Ribbon.RibbonSeparator separator4;
        internal Microsoft.Office.Tools.Ribbon.RibbonButton bSubOrder;
    }

    partial class ThisRibbonCollection
    {
        internal SubcontractRibbon SubcontractRibbon
        {
            get { return this.GetRibbon<SubcontractRibbon>(); }
        }
    }
}
