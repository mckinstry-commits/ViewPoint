namespace McK.SMQuotes.Viewpoint
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
            this.btnGetQuotes = new System.Windows.Forms.Button();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.cboCompany = new System.Windows.Forms.ComboBox();
            this.picLogo = new System.Windows.Forms.PictureBox();
            this.lblVersion = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.grpQuoteStatus = new System.Windows.Forms.GroupBox();
            this.rdoNew = new System.Windows.Forms.RadioButton();
            this.rdoCancelled = new System.Windows.Forms.RadioButton();
            this.rdoApproved = new System.Windows.Forms.RadioButton();
            this.rdoAll = new System.Windows.Forms.RadioButton();
            this.txtCustomer = new System.Windows.Forms.TextBox();
            this.label9 = new System.Windows.Forms.Label();
            this.btnPreview = new System.Windows.Forms.Button();
            this.btnEmail = new System.Windows.Forms.Button();
            this.btnSave = new System.Windows.Forms.Button();
            this.txtQuoteID = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.grpQuoteFormat = new System.Windows.Forms.GroupBox();
            this.rdoDetailedEquip = new System.Windows.Forms.RadioButton();
            this.rdoDetailed = new System.Windows.Forms.RadioButton();
            this.rdoStandard = new System.Windows.Forms.RadioButton();
            this.btnPrint = new System.Windows.Forms.Button();
            this.tmrBlinkControl = new System.Windows.Forms.Timer(this.components);
            this.cboTargetEnvironment = new System.Windows.Forms.ComboBox();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).BeginInit();
            this.grpQuoteStatus.SuspendLayout();
            this.grpQuoteFormat.SuspendLayout();
            this.SuspendLayout();
            // 
            // lblCompany
            // 
            this.lblCompany.AutoSize = true;
            this.lblCompany.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.lblCompany.Location = new System.Drawing.Point(-1, 124);
            this.lblCompany.Name = "lblCompany";
            this.lblCompany.Size = new System.Drawing.Size(92, 16);
            this.lblCompany.TabIndex = 6;
            this.lblCompany.Text = "SM Company:";
            // 
            // btnGetQuotes
            // 
            this.btnGetQuotes.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnGetQuotes.Location = new System.Drawing.Point(4, 500);
            this.btnGetQuotes.Name = "btnGetQuotes";
            this.btnGetQuotes.Size = new System.Drawing.Size(182, 50);
            this.btnGetQuotes.TabIndex = 12;
            this.btnGetQuotes.Text = "Get Quotes";
            this.btnGetQuotes.UseVisualStyleBackColor = true;
            this.btnGetQuotes.Click += new System.EventHandler(this.btnGetQuotes_Click);
            this.btnGetQuotes.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
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
            this.cboCompany.Location = new System.Drawing.Point(2, 143);
            this.cboCompany.Name = "cboCompany";
            this.cboCompany.Size = new System.Drawing.Size(187, 22);
            this.cboCompany.TabIndex = 0;
            this.cboCompany.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboCompany_DrawItem);
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
            this.lblVersion.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblVersion.Location = new System.Drawing.Point(60, 68);
            this.lblVersion.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblVersion.Name = "lblVersion";
            this.lblVersion.Size = new System.Drawing.Size(74, 20);
            this.lblVersion.TabIndex = 44;
            this.lblVersion.Text = "v1.0.0.0";
            this.lblVersion.UseCompatibleTextRendering = true;
            this.lblVersion.UseMnemonic = false;
            // 
            // label2
            // 
            this.label2.BackColor = System.Drawing.Color.Transparent;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.Location = new System.Drawing.Point(1, 51);
            this.label2.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(192, 18);
            this.label2.TabIndex = 42;
            this.label2.Text = "McK SM WO Quote Report";
            this.label2.UseMnemonic = false;
            // 
            // grpQuoteStatus
            // 
            this.grpQuoteStatus.Controls.Add(this.rdoNew);
            this.grpQuoteStatus.Controls.Add(this.rdoCancelled);
            this.grpQuoteStatus.Controls.Add(this.rdoApproved);
            this.grpQuoteStatus.Controls.Add(this.rdoAll);
            this.grpQuoteStatus.Cursor = System.Windows.Forms.Cursors.Hand;
            this.grpQuoteStatus.Location = new System.Drawing.Point(3, 397);
            this.grpQuoteStatus.Name = "grpQuoteStatus";
            this.grpQuoteStatus.Size = new System.Drawing.Size(182, 95);
            this.grpQuoteStatus.TabIndex = 7;
            this.grpQuoteStatus.TabStop = false;
            this.grpQuoteStatus.Text = "Quote Status";
            // 
            // rdoNew
            // 
            this.rdoNew.AutoSize = true;
            this.rdoNew.Location = new System.Drawing.Point(104, 21);
            this.rdoNew.Name = "rdoNew";
            this.rdoNew.Size = new System.Drawing.Size(53, 20);
            this.rdoNew.TabIndex = 9;
            this.rdoNew.Text = "New";
            this.rdoNew.UseVisualStyleBackColor = true;
            this.rdoNew.CheckedChanged += new System.EventHandler(this.radioButton_CheckedChanged);
            this.rdoNew.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // rdoCancelled
            // 
            this.rdoCancelled.AutoSize = true;
            this.rdoCancelled.Location = new System.Drawing.Point(11, 65);
            this.rdoCancelled.Name = "rdoCancelled";
            this.rdoCancelled.Size = new System.Drawing.Size(87, 20);
            this.rdoCancelled.TabIndex = 11;
            this.rdoCancelled.Text = "Cancelled";
            this.rdoCancelled.UseVisualStyleBackColor = true;
            this.rdoCancelled.CheckedChanged += new System.EventHandler(this.radioButton_CheckedChanged);
            this.rdoCancelled.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // rdoApproved
            // 
            this.rdoApproved.AutoSize = true;
            this.rdoApproved.Checked = true;
            this.rdoApproved.Location = new System.Drawing.Point(12, 41);
            this.rdoApproved.Name = "rdoApproved";
            this.rdoApproved.Size = new System.Drawing.Size(86, 20);
            this.rdoApproved.TabIndex = 10;
            this.rdoApproved.TabStop = true;
            this.rdoApproved.Text = "Approved";
            this.rdoApproved.UseVisualStyleBackColor = true;
            this.rdoApproved.CheckedChanged += new System.EventHandler(this.radioButton_CheckedChanged);
            this.rdoApproved.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // rdoAll
            // 
            this.rdoAll.AutoSize = true;
            this.rdoAll.Location = new System.Drawing.Point(12, 19);
            this.rdoAll.Name = "rdoAll";
            this.rdoAll.Size = new System.Drawing.Size(41, 20);
            this.rdoAll.TabIndex = 8;
            this.rdoAll.Text = "All";
            this.rdoAll.UseVisualStyleBackColor = true;
            this.rdoAll.CheckedChanged += new System.EventHandler(this.radioButton_CheckedChanged);
            this.rdoAll.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // txtCustomer
            // 
            this.txtCustomer.BackColor = System.Drawing.SystemColors.Info;
            this.txtCustomer.Location = new System.Drawing.Point(4, 258);
            this.txtCustomer.MaxLength = 4000;
            this.txtCustomer.Name = "txtCustomer";
            this.txtCustomer.Size = new System.Drawing.Size(186, 22);
            this.txtCustomer.TabIndex = 2;
            this.txtCustomer.TextChanged += new System.EventHandler(this.txtCustomer_TextChanged);
            this.txtCustomer.KeyDown += new System.Windows.Forms.KeyEventHandler(this.txtBillToCustomer_KeyDown);
            this.txtCustomer.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label9.Location = new System.Drawing.Point(0, 238);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(91, 16);
            this.label9.TabIndex = 61;
            this.label9.Text = "SM Customer:";
            // 
            // btnPreview
            // 
            this.btnPreview.BackColor = System.Drawing.SystemColors.ControlLight;
            this.btnPreview.Enabled = false;
            this.btnPreview.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPreview.Location = new System.Drawing.Point(4, 557);
            this.btnPreview.Name = "btnPreview";
            this.btnPreview.Size = new System.Drawing.Size(181, 50);
            this.btnPreview.TabIndex = 13;
            this.btnPreview.Text = "Preview Quotes";
            this.btnPreview.UseVisualStyleBackColor = true;
            this.btnPreview.Click += new System.EventHandler(this.btnPreview_Click);
            this.btnPreview.KeyUp += new System.Windows.Forms.KeyEventHandler(this.btnPreview_KeyUp);
            // 
            // btnEmail
            // 
            this.btnEmail.Enabled = false;
            this.btnEmail.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnEmail.Location = new System.Drawing.Point(4, 613);
            this.btnEmail.Name = "btnEmail";
            this.btnEmail.Size = new System.Drawing.Size(182, 50);
            this.btnEmail.TabIndex = 14;
            this.btnEmail.Text = "Email Quote PDF";
            this.btnEmail.UseVisualStyleBackColor = true;
            this.btnEmail.Click += new System.EventHandler(this.btnEmailQuotes_Click);
            // 
            // btnSave
            // 
            this.btnSave.Enabled = false;
            this.btnSave.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnSave.Location = new System.Drawing.Point(1, 725);
            this.btnSave.Name = "btnSave";
            this.btnSave.Size = new System.Drawing.Size(184, 46);
            this.btnSave.TabIndex = 16;
            this.btnSave.Text = "Save Quote Offline";
            this.btnSave.UseVisualStyleBackColor = true;
            this.btnSave.Click += new System.EventHandler(this.btnSaveQuotesOffline_Click);
            // 
            // txtQuoteID
            // 
            this.txtQuoteID.BackColor = System.Drawing.SystemColors.Info;
            this.txtQuoteID.Location = new System.Drawing.Point(3, 200);
            this.txtQuoteID.MaxLength = 4000;
            this.txtQuoteID.Name = "txtQuoteID";
            this.txtQuoteID.Size = new System.Drawing.Size(187, 22);
            this.txtQuoteID.TabIndex = 1;
            this.txtQuoteID.TextChanged += new System.EventHandler(this.txtQuoteID_TextChanged);
            this.txtQuoteID.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(1, 181);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(119, 16);
            this.label1.TabIndex = 74;
            this.label1.Text = "Work Order Quote:";
            // 
            // grpQuoteFormat
            // 
            this.grpQuoteFormat.Controls.Add(this.rdoDetailedEquip);
            this.grpQuoteFormat.Controls.Add(this.rdoDetailed);
            this.grpQuoteFormat.Controls.Add(this.rdoStandard);
            this.grpQuoteFormat.Cursor = System.Windows.Forms.Cursors.Hand;
            this.grpQuoteFormat.Location = new System.Drawing.Point(3, 296);
            this.grpQuoteFormat.Name = "grpQuoteFormat";
            this.grpQuoteFormat.Size = new System.Drawing.Size(182, 95);
            this.grpQuoteFormat.TabIndex = 3;
            this.grpQuoteFormat.TabStop = false;
            this.grpQuoteFormat.Text = "Quote Format";
            // 
            // rdoDetailedEquip
            // 
            this.rdoDetailedEquip.AutoSize = true;
            this.rdoDetailedEquip.Enabled = false;
            this.rdoDetailedEquip.Location = new System.Drawing.Point(11, 65);
            this.rdoDetailedEquip.Name = "rdoDetailedEquip";
            this.rdoDetailedEquip.Size = new System.Drawing.Size(140, 20);
            this.rdoDetailedEquip.TabIndex = 6;
            this.rdoDetailedEquip.Text = "Detailed with Equip";
            this.rdoDetailedEquip.UseVisualStyleBackColor = true;
            this.rdoDetailedEquip.CheckedChanged += new System.EventHandler(this.rdoDetailedEquip_CheckedChanged);
            // 
            // rdoDetailed
            // 
            this.rdoDetailed.AutoSize = true;
            this.rdoDetailed.Location = new System.Drawing.Point(12, 41);
            this.rdoDetailed.Name = "rdoDetailed";
            this.rdoDetailed.Size = new System.Drawing.Size(77, 20);
            this.rdoDetailed.TabIndex = 5;
            this.rdoDetailed.Text = "Detailed";
            this.rdoDetailed.UseVisualStyleBackColor = true;
            this.rdoDetailed.CheckedChanged += new System.EventHandler(this.rdoDetailed_CheckedChanged);
            this.rdoDetailed.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // rdoStandard
            // 
            this.rdoStandard.AutoSize = true;
            this.rdoStandard.Checked = true;
            this.rdoStandard.Location = new System.Drawing.Point(12, 19);
            this.rdoStandard.Name = "rdoStandard";
            this.rdoStandard.Size = new System.Drawing.Size(81, 20);
            this.rdoStandard.TabIndex = 4;
            this.rdoStandard.TabStop = true;
            this.rdoStandard.Text = "Standard";
            this.rdoStandard.UseVisualStyleBackColor = true;
            this.rdoStandard.CheckedChanged += new System.EventHandler(this.rdoStandard_CheckedChanged);
            this.rdoStandard.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // btnPrint
            // 
            this.btnPrint.Enabled = false;
            this.btnPrint.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPrint.Location = new System.Drawing.Point(3, 669);
            this.btnPrint.Name = "btnPrint";
            this.btnPrint.Size = new System.Drawing.Size(182, 50);
            this.btnPrint.TabIndex = 15;
            this.btnPrint.Text = "Print Quotes";
            this.btnPrint.UseVisualStyleBackColor = true;
            this.btnPrint.Click += new System.EventHandler(this.btnPrint_Click);
            // 
            // tmrBlinkControl
            // 
            this.tmrBlinkControl.Interval = 300;
            this.tmrBlinkControl.Tick += new System.EventHandler(this.tmrBlinkControl_Tick);
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
            this.cboTargetEnvironment.Location = new System.Drawing.Point(25, 84);
            this.cboTargetEnvironment.Name = "cboTargetEnvironment";
            this.cboTargetEnvironment.Size = new System.Drawing.Size(139, 32);
            this.cboTargetEnvironment.TabIndex = 82;
            this.cboTargetEnvironment.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboTargetEnvironment_DrawItem);
            this.cboTargetEnvironment.SelectedIndexChanged += new System.EventHandler(this.cboTargetEnvironment_SelectedIndexChanged);
            // 
            // ActionPane1
            // 
            this.AutoValidate = System.Windows.Forms.AutoValidate.EnableAllowFocusChange;
            this.Controls.Add(this.cboTargetEnvironment);
            this.Controls.Add(this.btnPrint);
            this.Controls.Add(this.grpQuoteFormat);
            this.Controls.Add(this.txtQuoteID);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.btnSave);
            this.Controls.Add(this.btnEmail);
            this.Controls.Add(this.btnPreview);
            this.Controls.Add(this.txtCustomer);
            this.Controls.Add(this.label9);
            this.Controls.Add(this.grpQuoteStatus);
            this.Controls.Add(this.lblVersion);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.cboCompany);
            this.Controls.Add(this.btnGetQuotes);
            this.Controls.Add(this.lblCompany);
            this.Controls.Add(this.picLogo);
            this.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.ForeColor = System.Drawing.SystemColors.WindowText;
            this.Name = "ActionPane1";
            this.Size = new System.Drawing.Size(189, 775);
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).EndInit();
            this.grpQuoteStatus.ResumeLayout(false);
            this.grpQuoteStatus.PerformLayout();
            this.grpQuoteFormat.ResumeLayout(false);
            this.grpQuoteFormat.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion
        private System.Windows.Forms.Label lblCompany;
        internal System.Windows.Forms.Button btnGetQuotes;
        private System.Windows.Forms.ErrorProvider errorProvider1;
        internal System.Windows.Forms.ComboBox cboCompany;
        private System.Windows.Forms.Label lblVersion;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.PictureBox picLogo;
        private System.Windows.Forms.GroupBox grpQuoteStatus;
        private System.Windows.Forms.RadioButton rdoCancelled;
        private System.Windows.Forms.RadioButton rdoApproved;
        private System.Windows.Forms.RadioButton rdoAll;
        internal System.Windows.Forms.TextBox txtCustomer;
        private System.Windows.Forms.Label label9;
        internal System.Windows.Forms.Button btnPreview;
        internal System.Windows.Forms.Button btnEmail;
        private System.Windows.Forms.RadioButton rdoNew;
        internal System.Windows.Forms.Button btnSave;
        private System.Windows.Forms.GroupBox grpQuoteFormat;
        private System.Windows.Forms.RadioButton rdoDetailedEquip;
        private System.Windows.Forms.RadioButton rdoDetailed;
        private System.Windows.Forms.RadioButton rdoStandard;
        internal System.Windows.Forms.TextBox txtQuoteID;
        private System.Windows.Forms.Label label1;
        internal System.Windows.Forms.Button btnPrint;
        private System.Windows.Forms.Timer tmrBlinkControl;
        internal System.Windows.Forms.ComboBox cboTargetEnvironment;
    }
}
