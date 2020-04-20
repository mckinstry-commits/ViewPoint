namespace McKContractClose
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
            this.picLogo = new System.Windows.Forms.PictureBox();
            this.lblContract = new System.Windows.Forms.Label();
            this.lblMonth = new System.Windows.Forms.Label();
            this.cboMonth = new System.Windows.Forms.ComboBox();
            this.btnCreateBatch = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.cboCloseType = new System.Windows.Forms.ComboBox();
            this.label3 = new System.Windows.Forms.Label();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.lblBatch = new System.Windows.Forms.Label();
            this.lblRecordCnt = new System.Windows.Forms.Label();
            this.cboCompany = new System.Windows.Forms.ComboBox();
            this.btnReset = new System.Windows.Forms.Button();
            this.lblResetInfo = new System.Windows.Forms.Label();
            this.lblVersion = new System.Windows.Forms.Label();
            this.lblTitle = new System.Windows.Forms.Label();
            this.cboTargetEnvironment = new System.Windows.Forms.ComboBox();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            this.SuspendLayout();
            // 
            // picLogo
            // 
            this.picLogo.Image = ((System.Drawing.Image)(resources.GetObject("picLogo.Image")));
            this.picLogo.Location = new System.Drawing.Point(3, 3);
            this.picLogo.Name = "picLogo";
            this.picLogo.Size = new System.Drawing.Size(91, 48);
            this.picLogo.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picLogo.TabIndex = 4;
            this.picLogo.TabStop = false;
            // 
            // lblContract
            // 
            this.lblContract.AutoSize = true;
            this.lblContract.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.lblContract.Location = new System.Drawing.Point(3, 159);
            this.lblContract.Name = "lblContract";
            this.lblContract.Size = new System.Drawing.Size(69, 16);
            this.lblContract.TabIndex = 6;
            this.lblContract.Text = "Company:";
            // 
            // lblMonth
            // 
            this.lblMonth.AutoSize = true;
            this.lblMonth.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.lblMonth.Location = new System.Drawing.Point(4, 229);
            this.lblMonth.Name = "lblMonth";
            this.lblMonth.Size = new System.Drawing.Size(77, 16);
            this.lblMonth.TabIndex = 8;
            this.lblMonth.Text = "Post Month:";
            // 
            // cboMonth
            // 
            this.cboMonth.BackColor = System.Drawing.SystemColors.Info;
            this.cboMonth.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboMonth.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboMonth.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.cboMonth.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboMonth.FormattingEnabled = true;
            this.cboMonth.Location = new System.Drawing.Point(5, 254);
            this.cboMonth.Name = "cboMonth";
            this.cboMonth.Size = new System.Drawing.Size(96, 22);
            this.cboMonth.TabIndex = 1;
            this.cboMonth.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItemBlack);
            this.cboMonth.SelectedIndexChanged += new System.EventHandler(this.cboMonth_SelectedIndexChanged);
            // 
            // btnCreateBatch
            // 
            this.btnCreateBatch.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnCreateBatch.Location = new System.Drawing.Point(5, 377);
            this.btnCreateBatch.Name = "btnCreateBatch";
            this.btnCreateBatch.Size = new System.Drawing.Size(119, 64);
            this.btnCreateBatch.TabIndex = 3;
            this.btnCreateBatch.Text = "Create Batch";
            this.btnCreateBatch.UseVisualStyleBackColor = true;
            this.btnCreateBatch.Click += new System.EventHandler(this.btnCreateBatch_Click);
            this.btnCreateBatch.KeyUp += new System.Windows.Forms.KeyEventHandler(this.btnCreateBatch_KeyUp);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.label1.Location = new System.Drawing.Point(4, 460);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(48, 16);
            this.label1.TabIndex = 10;
            this.label1.Text = "Batch: ";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.label2.Location = new System.Drawing.Point(4, 532);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(125, 16);
            this.label2.TabIndex = 11;
            this.label2.Text = "Records Received:";
            // 
            // cboCloseType
            // 
            this.cboCloseType.BackColor = System.Drawing.SystemColors.Info;
            this.cboCloseType.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboCloseType.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboCloseType.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cboCloseType.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboCloseType.FormattingEnabled = true;
            this.cboCloseType.Location = new System.Drawing.Point(5, 328);
            this.cboCloseType.Name = "cboCloseType";
            this.cboCloseType.Size = new System.Drawing.Size(96, 22);
            this.cboCloseType.TabIndex = 2;
            this.cboCloseType.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItemBlack);
            this.cboCloseType.SelectedIndexChanged += new System.EventHandler(this.cboCloseType_SelectedIndexChanged);
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.label3.Location = new System.Drawing.Point(5, 302);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(81, 16);
            this.label3.TabIndex = 13;
            this.label3.Text = "Close Type:";
            // 
            // errorProvider1
            // 
            this.errorProvider1.ContainerControl = this;
            // 
            // lblBatch
            // 
            this.lblBatch.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.lblBatch.Font = new System.Drawing.Font("Microsoft Sans Serif", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblBatch.Location = new System.Drawing.Point(7, 485);
            this.lblBatch.Name = "lblBatch";
            this.lblBatch.Size = new System.Drawing.Size(110, 33);
            this.lblBatch.TabIndex = 15;
            this.lblBatch.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // lblRecordCnt
            // 
            this.lblRecordCnt.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.lblRecordCnt.Font = new System.Drawing.Font("Microsoft Sans Serif", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblRecordCnt.Location = new System.Drawing.Point(7, 557);
            this.lblRecordCnt.Name = "lblRecordCnt";
            this.lblRecordCnt.Size = new System.Drawing.Size(110, 30);
            this.lblRecordCnt.TabIndex = 16;
            this.lblRecordCnt.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
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
            this.cboCompany.Location = new System.Drawing.Point(4, 187);
            this.cboCompany.Name = "cboCompany";
            this.cboCompany.Size = new System.Drawing.Size(165, 22);
            this.cboCompany.TabIndex = 0;
            this.cboCompany.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItemBlack);
            this.cboCompany.KeyUp += new System.Windows.Forms.KeyEventHandler(this.cboCompany_KeyUp);
            this.cboCompany.Leave += new System.EventHandler(this.cboCompany_Leave);
            // 
            // btnReset
            // 
            this.btnReset.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnReset.Location = new System.Drawing.Point(5, 609);
            this.btnReset.Name = "btnReset";
            this.btnReset.Size = new System.Drawing.Size(94, 52);
            this.btnReset.TabIndex = 17;
            this.btnReset.Text = "Reset";
            this.btnReset.UseVisualStyleBackColor = true;
            this.btnReset.Click += new System.EventHandler(this.btnReset_Click);
            // 
            // lblResetInfo
            // 
            this.lblResetInfo.AutoSize = true;
            this.lblResetInfo.Location = new System.Drawing.Point(7, 668);
            this.lblResetInfo.Name = "lblResetInfo";
            this.lblResetInfo.Size = new System.Drawing.Size(117, 13);
            this.lblResetInfo.TabIndex = 18;
            this.lblResetInfo.Text = "Enter a new set of data";
            // 
            // lblVersion
            // 
            this.lblVersion.Location = new System.Drawing.Point(12, 86);
            this.lblVersion.Name = "lblVersion";
            this.lblVersion.Size = new System.Drawing.Size(151, 19);
            this.lblVersion.TabIndex = 83;
            this.lblVersion.Text = "v.1.0.2.0";
            this.lblVersion.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // lblTitle
            // 
            this.lblTitle.BackColor = System.Drawing.Color.Transparent;
            this.lblTitle.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblTitle.Location = new System.Drawing.Point(2, 54);
            this.lblTitle.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblTitle.Name = "lblTitle";
            this.lblTitle.Size = new System.Drawing.Size(166, 34);
            this.lblTitle.TabIndex = 85;
            this.lblTitle.Text = "MCK Contract Close";
            this.lblTitle.UseMnemonic = false;
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
            this.cboTargetEnvironment.Location = new System.Drawing.Point(24, 106);
            this.cboTargetEnvironment.Name = "cboTargetEnvironment";
            this.cboTargetEnvironment.Size = new System.Drawing.Size(139, 32);
            this.cboTargetEnvironment.TabIndex = 84;
            this.cboTargetEnvironment.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItemYellow);
            this.cboTargetEnvironment.SelectedIndexChanged += new System.EventHandler(this.cboTargetEnvironment_SelectedIndexChanged);
            // 
            // ActionPane1
            // 
            this.Controls.Add(this.lblVersion);
            this.Controls.Add(this.lblTitle);
            this.Controls.Add(this.cboTargetEnvironment);
            this.Controls.Add(this.lblResetInfo);
            this.Controls.Add(this.btnReset);
            this.Controls.Add(this.cboCompany);
            this.Controls.Add(this.lblRecordCnt);
            this.Controls.Add(this.lblBatch);
            this.Controls.Add(this.cboCloseType);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.btnCreateBatch);
            this.Controls.Add(this.cboMonth);
            this.Controls.Add(this.lblMonth);
            this.Controls.Add(this.lblContract);
            this.Controls.Add(this.picLogo);
            this.ForeColor = System.Drawing.SystemColors.WindowText;
            this.Name = "ActionPane1";
            this.Size = new System.Drawing.Size(180, 720);
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.PictureBox picLogo;
        private System.Windows.Forms.Label lblContract;
        public System.Windows.Forms.Label lblMonth;
        public System.Windows.Forms.ComboBox cboMonth;
        public System.Windows.Forms.Button btnCreateBatch;
        public System.Windows.Forms.Label label1;
        public System.Windows.Forms.Label label2;
        private System.Windows.Forms.ComboBox cboCloseType;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.ErrorProvider errorProvider1;
        private System.Windows.Forms.Label lblRecordCnt;
        private System.Windows.Forms.Label lblBatch;
        private System.Windows.Forms.ComboBox cboCompany;
        public System.Windows.Forms.Button btnReset;
        private System.Windows.Forms.Label lblResetInfo;
        private System.Windows.Forms.Label lblVersion;
        internal System.Windows.Forms.Label lblTitle;
        internal System.Windows.Forms.ComboBox cboTargetEnvironment;
    }
}
