namespace McK.ARStatement.Viewpoint
{
    [System.ComponentModel.ToolboxItemAttribute(false)]
    partial class ActionPane1
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
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
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(ActionPane1));
            this.lblCompany = new System.Windows.Forms.Label();
            this.btnGetStatement = new System.Windows.Forms.Button();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.cboCompany = new System.Windows.Forms.ComboBox();
            this.picLogo = new System.Windows.Forms.PictureBox();
            this.lblVersion = new System.Windows.Forms.Label();
            this.lblTitle = new System.Windows.Forms.Label();
            this.txtCustomerList = new System.Windows.Forms.TextBox();
            this.label9 = new System.Windows.Forms.Label();
            this.btnPreview = new System.Windows.Forms.Button();
            this.btnDeliver = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.txtStatementDate = new System.Windows.Forms.MaskedTextBox();
            this.txtTransThruDate = new System.Windows.Forms.MaskedTextBox();
            this.label4 = new System.Windows.Forms.Label();
            this.cboARGroups = new System.Windows.Forms.ComboBox();
            this.cboTargetEnvironment = new System.Windows.Forms.ComboBox();
            this.btnCopyOffline = new System.Windows.Forms.Button();
            this.ckbPreview = new System.Windows.Forms.CheckBox();
            this.label2 = new System.Windows.Forms.Label();
            this.lblRecCnt = new System.Windows.Forms.Label();
            this.btnMoveNCustomers = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).BeginInit();
            this.SuspendLayout();
            // 
            // lblCompany
            // 
            this.lblCompany.AutoSize = true;
            this.lblCompany.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.lblCompany.Location = new System.Drawing.Point(-3, 153);
            this.lblCompany.Name = "lblCompany";
            this.lblCompany.Size = new System.Drawing.Size(69, 16);
            this.lblCompany.TabIndex = 6;
            this.lblCompany.Text = "Company:";
            // 
            // btnGetStatement
            // 
            this.btnGetStatement.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnGetStatement.Location = new System.Drawing.Point(2, 488);
            this.btnGetStatement.Name = "btnGetStatement";
            this.btnGetStatement.Size = new System.Drawing.Size(182, 50);
            this.btnGetStatement.TabIndex = 6;
            this.btnGetStatement.Text = "Get Statement";
            this.btnGetStatement.UseVisualStyleBackColor = true;
            this.btnGetStatement.Click += new System.EventHandler(this.btnGetStatements_Click);
            this.btnGetStatement.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // errorProvider1
            // 
            this.errorProvider1.ContainerControl = this;
            // 
            // cboCompany
            // 
            this.cboCompany.BackColor = System.Drawing.SystemColors.Info;
            this.cboCompany.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboCompany.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboCompany.DropDownWidth = 200;
            this.cboCompany.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cboCompany.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboCompany.FormattingEnabled = true;
            this.cboCompany.Location = new System.Drawing.Point(4, 176);
            this.cboCompany.Name = "cboCompany";
            this.cboCompany.Size = new System.Drawing.Size(187, 22);
            this.cboCompany.TabIndex = 0;
            this.cboCompany.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItem);
            this.cboCompany.KeyUp += new System.Windows.Forms.KeyEventHandler(this.cboCompany_KeyUp);
            this.cboCompany.Leave += new System.EventHandler(this.cboCompany_Leave);
            // 
            // picLogo
            // 
            this.picLogo.Image = ((System.Drawing.Image)(resources.GetObject("picLogo.Image")));
            this.picLogo.Location = new System.Drawing.Point(0, 0);
            this.picLogo.Name = "picLogo";
            this.picLogo.Size = new System.Drawing.Size(95, 48);
            this.picLogo.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picLogo.TabIndex = 4;
            this.picLogo.TabStop = false;
            // 
            // lblVersion
            // 
            this.lblVersion.BackColor = System.Drawing.Color.Transparent;
            this.lblVersion.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblVersion.Location = new System.Drawing.Point(24, 94);
            this.lblVersion.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblVersion.Name = "lblVersion";
            this.lblVersion.Size = new System.Drawing.Size(139, 19);
            this.lblVersion.TabIndex = 44;
            this.lblVersion.Text = "v1.0.0.0";
            this.lblVersion.TextAlign = System.Drawing.ContentAlignment.BottomCenter;
            this.lblVersion.UseCompatibleTextRendering = true;
            this.lblVersion.UseMnemonic = false;
            // 
            // lblTitle
            // 
            this.lblTitle.BackColor = System.Drawing.Color.Transparent;
            this.lblTitle.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblTitle.Location = new System.Drawing.Point(1, 51);
            this.lblTitle.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblTitle.Name = "lblTitle";
            this.lblTitle.Size = new System.Drawing.Size(181, 43);
            this.lblTitle.TabIndex = 42;
            this.lblTitle.Text = "AR Open Item Statement";
            this.lblTitle.UseMnemonic = false;
            // 
            // txtCustomerList
            // 
            this.txtCustomerList.BackColor = System.Drawing.SystemColors.Info;
            this.txtCustomerList.Location = new System.Drawing.Point(4, 233);
            this.txtCustomerList.MaxLength = 4000;
            this.txtCustomerList.Name = "txtCustomerList";
            this.txtCustomerList.Size = new System.Drawing.Size(186, 22);
            this.txtCustomerList.TabIndex = 1;
            this.txtCustomerList.KeyDown += new System.Windows.Forms.KeyEventHandler(this.txtBillToCustomer_KeyDown);
            this.txtCustomerList.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label9.Location = new System.Drawing.Point(-3, 210);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(68, 16);
            this.label9.TabIndex = 61;
            this.label9.Text = "Customer:";
            // 
            // btnPreview
            // 
            this.btnPreview.BackColor = System.Drawing.SystemColors.ControlLight;
            this.btnPreview.Enabled = false;
            this.btnPreview.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPreview.Location = new System.Drawing.Point(3, 544);
            this.btnPreview.Name = "btnPreview";
            this.btnPreview.Size = new System.Drawing.Size(181, 50);
            this.btnPreview.TabIndex = 7;
            this.btnPreview.Text = "Preview Statements";
            this.btnPreview.UseVisualStyleBackColor = true;
            this.btnPreview.Click += new System.EventHandler(this.btnPreview_Click);
            this.btnPreview.KeyUp += new System.Windows.Forms.KeyEventHandler(this.btnPreview_KeyUp);
            // 
            // btnDeliver
            // 
            this.btnDeliver.BackColor = System.Drawing.SystemColors.ControlLight;
            this.btnDeliver.Enabled = false;
            this.btnDeliver.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnDeliver.Location = new System.Drawing.Point(3, 600);
            this.btnDeliver.Name = "btnDeliver";
            this.btnDeliver.Size = new System.Drawing.Size(182, 50);
            this.btnDeliver.TabIndex = 8;
            this.btnDeliver.Text = "Deliver Statements";
            this.btnDeliver.UseVisualStyleBackColor = false;
            this.btnDeliver.Click += new System.EventHandler(this.btnDeliver_Click);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(-2, 272);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(85, 16);
            this.label1.TabIndex = 74;
            this.label1.Text = "AR Group(s):";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label3.Location = new System.Drawing.Point(-2, 330);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(110, 16);
            this.label3.TabIndex = 76;
            this.label3.Text = "Statement Month:";
            // 
            // txtStatementDate
            // 
            this.txtStatementDate.BackColor = System.Drawing.SystemColors.Info;
            this.txtStatementDate.Location = new System.Drawing.Point(4, 352);
            this.txtStatementDate.Mask = "00/00";
            this.txtStatementDate.Name = "txtStatementDate";
            this.txtStatementDate.Size = new System.Drawing.Size(56, 22);
            this.txtStatementDate.TabIndex = 4;
            this.txtStatementDate.ValidatingType = typeof(System.DateTime);
            this.txtStatementDate.TextChanged += new System.EventHandler(this.txtStatementDate_TextChanged);
            this.txtStatementDate.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // txtTransThruDate
            // 
            this.txtTransThruDate.BackColor = System.Drawing.SystemColors.Info;
            this.txtTransThruDate.Enabled = false;
            this.txtTransThruDate.Location = new System.Drawing.Point(3, 411);
            this.txtTransThruDate.Mask = "00/00/00";
            this.txtTransThruDate.Name = "txtTransThruDate";
            this.txtTransThruDate.Size = new System.Drawing.Size(90, 22);
            this.txtTransThruDate.TabIndex = 5;
            this.txtTransThruDate.ValidatingType = typeof(System.DateTime);
            this.txtTransThruDate.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label4.Location = new System.Drawing.Point(-2, 389);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(142, 16);
            this.label4.TabIndex = 78;
            this.label4.Text = "Transactions Through:";
            // 
            // cboARGroups
            // 
            this.cboARGroups.BackColor = System.Drawing.SystemColors.Info;
            this.cboARGroups.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboARGroups.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboARGroups.DropDownWidth = 100;
            this.cboARGroups.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cboARGroups.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboARGroups.FormattingEnabled = true;
            this.cboARGroups.Items.AddRange(new object[] {
            "All",
            "B-Both",
            "C-Corporate",
            "S-Service",
            "X-Exceptions"});
            this.cboARGroups.Location = new System.Drawing.Point(4, 295);
            this.cboARGroups.Name = "cboARGroups";
            this.cboARGroups.Size = new System.Drawing.Size(101, 22);
            this.cboARGroups.TabIndex = 3;
            this.cboARGroups.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItem);
            this.cboARGroups.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // cboTargetEnvironment
            // 
            this.cboTargetEnvironment.BackColor = System.Drawing.Color.Black;
            this.cboTargetEnvironment.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboTargetEnvironment.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboTargetEnvironment.DropDownWidth = 200;
            this.cboTargetEnvironment.Font = new System.Drawing.Font("Microsoft Sans Serif", 14.25F, System.Drawing.FontStyle.Bold);
            this.cboTargetEnvironment.ForeColor = System.Drawing.Color.Yellow;
            this.cboTargetEnvironment.FormattingEnabled = true;
            this.cboTargetEnvironment.ItemHeight = 26;
            this.cboTargetEnvironment.Location = new System.Drawing.Point(24, 113);
            this.cboTargetEnvironment.Name = "cboTargetEnvironment";
            this.cboTargetEnvironment.Size = new System.Drawing.Size(139, 32);
            this.cboTargetEnvironment.TabIndex = 80;
            this.cboTargetEnvironment.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItem1);
            this.cboTargetEnvironment.SelectedIndexChanged += new System.EventHandler(this.cboTargetEnvironment_SelectedIndexChanged);
            // 
            // btnCopyOffline
            // 
            this.btnCopyOffline.BackColor = System.Drawing.Color.Gainsboro;
            this.btnCopyOffline.Enabled = false;
            this.btnCopyOffline.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnCopyOffline.Location = new System.Drawing.Point(3, 712);
            this.btnCopyOffline.Name = "btnCopyOffline";
            this.btnCopyOffline.Size = new System.Drawing.Size(182, 50);
            this.btnCopyOffline.TabIndex = 81;
            this.btnCopyOffline.Text = "Copy Grid Offline";
            this.btnCopyOffline.UseVisualStyleBackColor = false;
            this.btnCopyOffline.Click += new System.EventHandler(this.btnCopyOffline_Click);
            // 
            // ckbPreview
            // 
            this.ckbPreview.AutoSize = true;
            this.ckbPreview.Checked = true;
            this.ckbPreview.CheckState = System.Windows.Forms.CheckState.Checked;
            this.ckbPreview.Enabled = false;
            this.ckbPreview.Location = new System.Drawing.Point(3, 452);
            this.ckbPreview.Name = "ckbPreview";
            this.ckbPreview.Size = new System.Drawing.Size(75, 20);
            this.ckbPreview.TabIndex = 82;
            this.ckbPreview.Text = "Preview";
            this.ckbPreview.UseVisualStyleBackColor = true;
            this.ckbPreview.CheckedChanged += new System.EventHandler(this.ckbPreview_CheckedChanged);
            // 
            // label2
            // 
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.Location = new System.Drawing.Point(123, 317);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(59, 35);
            this.label2.TabIndex = 83;
            this.label2.Text = "Ready to Send:";
            // 
            // lblRecCnt
            // 
            this.lblRecCnt.BackColor = System.Drawing.Color.Black;
            this.lblRecCnt.FlatStyle = System.Windows.Forms.FlatStyle.System;
            this.lblRecCnt.Font = new System.Drawing.Font("Microsoft Sans Serif", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblRecCnt.ForeColor = System.Drawing.SystemColors.Info;
            this.lblRecCnt.Location = new System.Drawing.Point(124, 352);
            this.lblRecCnt.Name = "lblRecCnt";
            this.lblRecCnt.Size = new System.Drawing.Size(53, 24);
            this.lblRecCnt.TabIndex = 84;
            this.lblRecCnt.TextAlign = System.Drawing.ContentAlignment.BottomCenter;
            this.lblRecCnt.UseMnemonic = false;
            // 
            // btnMoveNCustomers
            // 
            this.btnMoveNCustomers.BackColor = System.Drawing.SystemColors.ControlLight;
            this.btnMoveNCustomers.Enabled = false;
            this.btnMoveNCustomers.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnMoveNCustomers.ForeColor = System.Drawing.SystemColors.WindowText;
            this.btnMoveNCustomers.Location = new System.Drawing.Point(4, 656);
            this.btnMoveNCustomers.Name = "btnMoveNCustomers";
            this.btnMoveNCustomers.Size = new System.Drawing.Size(182, 50);
            this.btnMoveNCustomers.TabIndex = 85;
            this.btnMoveNCustomers.Text = "Move \"N\" Customers to NewTab →";
            this.btnMoveNCustomers.UseVisualStyleBackColor = false;
            this.btnMoveNCustomers.Click += new System.EventHandler(this.btnMoveNCustomers_Click);
            // 
            // ActionPane1
            // 
            this.AutoScroll = true;
            this.AutoValidate = System.Windows.Forms.AutoValidate.EnableAllowFocusChange;
            this.BackColor = System.Drawing.SystemColors.ControlLightLight;
            this.Controls.Add(this.btnMoveNCustomers);
            this.Controls.Add(this.lblRecCnt);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.ckbPreview);
            this.Controls.Add(this.btnCopyOffline);
            this.Controls.Add(this.cboTargetEnvironment);
            this.Controls.Add(this.cboARGroups);
            this.Controls.Add(this.txtTransThruDate);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.txtStatementDate);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.btnDeliver);
            this.Controls.Add(this.btnPreview);
            this.Controls.Add(this.txtCustomerList);
            this.Controls.Add(this.label9);
            this.Controls.Add(this.lblVersion);
            this.Controls.Add(this.lblTitle);
            this.Controls.Add(this.cboCompany);
            this.Controls.Add(this.btnGetStatement);
            this.Controls.Add(this.lblCompany);
            this.Controls.Add(this.picLogo);
            this.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.ForeColor = System.Drawing.SystemColors.WindowText;
            this.Name = "ActionPane1";
            this.Size = new System.Drawing.Size(196, 765);
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion
        private System.Windows.Forms.Label lblCompany;
        internal System.Windows.Forms.Button btnGetStatement;
        private System.Windows.Forms.ErrorProvider errorProvider1;
        internal System.Windows.Forms.ComboBox cboCompany;
        private System.Windows.Forms.Label lblVersion;
        internal System.Windows.Forms.Label lblTitle;
        private System.Windows.Forms.PictureBox picLogo;
        internal System.Windows.Forms.TextBox txtCustomerList;
        private System.Windows.Forms.Label label9;
        internal System.Windows.Forms.Button btnPreview;
        internal System.Windows.Forms.Button btnDeliver;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.MaskedTextBox txtTransThruDate;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.MaskedTextBox txtStatementDate;
        private System.Windows.Forms.Label label3;
        internal System.Windows.Forms.ComboBox cboARGroups;
        internal System.Windows.Forms.ComboBox cboTargetEnvironment;
        internal System.Windows.Forms.Button btnCopyOffline;
        internal System.Windows.Forms.CheckBox ckbPreview;
        internal System.Windows.Forms.Label lblRecCnt;
        private System.Windows.Forms.Label label2;
        internal System.Windows.Forms.Button btnMoveNCustomers;
    }
}
