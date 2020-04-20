namespace McKUserCreation
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
            this.btnPostUsers = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.cboRole = new System.Windows.Forms.ComboBox();
            this.label3 = new System.Windows.Forms.Label();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.lblBatch = new System.Windows.Forms.Label();
            this.lblRecordCnt = new System.Windows.Forms.Label();
            this.cboCompany = new System.Windows.Forms.ComboBox();
            this.btnReset = new System.Windows.Forms.Button();
            this.lblResetInfo = new System.Windows.Forms.Label();
            this.lblVersion = new System.Windows.Forms.Label();
            this.tmrAlertCell = new System.Windows.Forms.Timer(this.components);
            this.lblAppName = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            this.SuspendLayout();
            // 
            // picLogo
            // 
            this.picLogo.Image = ((System.Drawing.Image)(resources.GetObject("picLogo.Image")));
            this.picLogo.Location = new System.Drawing.Point(12, 13);
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
            this.lblContract.Location = new System.Drawing.Point(10, 76);
            this.lblContract.Name = "lblContract";
            this.lblContract.Size = new System.Drawing.Size(69, 16);
            this.lblContract.TabIndex = 6;
            this.lblContract.Text = "Company:";
            // 
            // btnPostUsers
            // 
            this.btnPostUsers.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPostUsers.Location = new System.Drawing.Point(12, 243);
            this.btnPostUsers.Name = "btnPostUsers";
            this.btnPostUsers.Size = new System.Drawing.Size(94, 52);
            this.btnPostUsers.TabIndex = 3;
            this.btnPostUsers.Text = "Post";
            this.btnPostUsers.UseVisualStyleBackColor = true;
            this.btnPostUsers.Click += new System.EventHandler(this.btnPostUsers_Click);
            this.btnPostUsers.KeyUp += new System.Windows.Forms.KeyEventHandler(this.btnPostUsers_KeyUp);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.label1.Location = new System.Drawing.Point(9, 357);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(48, 16);
            this.label1.TabIndex = 10;
            this.label1.Text = "Batch: ";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.label2.Location = new System.Drawing.Point(9, 429);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(125, 16);
            this.label2.TabIndex = 11;
            this.label2.Text = "Records Received:";
            // 
            // cboRole
            // 
            this.cboRole.BackColor = System.Drawing.SystemColors.Info;
            this.cboRole.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboRole.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboRole.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cboRole.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboRole.FormattingEnabled = true;
            this.cboRole.Location = new System.Drawing.Point(13, 184);
            this.cboRole.Name = "cboRole";
            this.cboRole.Size = new System.Drawing.Size(161, 22);
            this.cboRole.TabIndex = 2;
            this.cboRole.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItem);
            this.cboRole.SelectedIndexChanged += new System.EventHandler(this.cboCloseType_SelectedIndexChanged);
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.label3.Location = new System.Drawing.Point(13, 158);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(40, 16);
            this.label3.TabIndex = 13;
            this.label3.Text = "Role:";
            // 
            // errorProvider1
            // 
            this.errorProvider1.ContainerControl = this;
            // 
            // lblBatch
            // 
            this.lblBatch.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.lblBatch.Font = new System.Drawing.Font("Microsoft Sans Serif", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblBatch.Location = new System.Drawing.Point(12, 382);
            this.lblBatch.Name = "lblBatch";
            this.lblBatch.Size = new System.Drawing.Size(110, 33);
            this.lblBatch.TabIndex = 15;
            this.lblBatch.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // lblRecordCnt
            // 
            this.lblRecordCnt.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.lblRecordCnt.Font = new System.Drawing.Font("Microsoft Sans Serif", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblRecordCnt.Location = new System.Drawing.Point(12, 454);
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
            this.cboCompany.Location = new System.Drawing.Point(11, 104);
            this.cboCompany.Name = "cboCompany";
            this.cboCompany.Size = new System.Drawing.Size(187, 22);
            this.cboCompany.TabIndex = 0;
            this.cboCompany.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItem);
            this.cboCompany.KeyUp += new System.Windows.Forms.KeyEventHandler(this.cboCompany_KeyUp);
            this.cboCompany.Leave += new System.EventHandler(this.cboCompany_Leave);
            // 
            // btnReset
            // 
            this.btnReset.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnReset.Location = new System.Drawing.Point(11, 522);
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
            this.lblResetInfo.Location = new System.Drawing.Point(9, 581);
            this.lblResetInfo.Name = "lblResetInfo";
            this.lblResetInfo.Size = new System.Drawing.Size(117, 13);
            this.lblResetInfo.TabIndex = 18;
            this.lblResetInfo.Text = "Enter a new set of data";
            // 
            // lblVersion
            // 
            this.lblVersion.Location = new System.Drawing.Point(0, 663);
            this.lblVersion.Name = "lblVersion";
            this.lblVersion.Size = new System.Drawing.Size(213, 15);
            this.lblVersion.TabIndex = 19;
            this.lblVersion.Text = "v.1.0.1.2";
            this.lblVersion.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // tmrAlertCell
            // 
            this.tmrAlertCell.Interval = 450;
            this.tmrAlertCell.Tick += new System.EventHandler(this.tmrAlertCell_Tick);
            // 
            // lblAppName
            // 
            this.lblAppName.BackColor = System.Drawing.Color.Transparent;
            this.lblAppName.Location = new System.Drawing.Point(0, 681);
            this.lblAppName.Name = "lblAppName";
            this.lblAppName.Size = new System.Drawing.Size(213, 21);
            this.lblAppName.TabIndex = 21;
            this.lblAppName.Text = "(Staging)";
            this.lblAppName.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // ActionPane1
            // 
            this.Controls.Add(this.lblAppName);
            this.Controls.Add(this.lblVersion);
            this.Controls.Add(this.lblResetInfo);
            this.Controls.Add(this.btnReset);
            this.Controls.Add(this.cboCompany);
            this.Controls.Add(this.lblRecordCnt);
            this.Controls.Add(this.lblBatch);
            this.Controls.Add(this.cboRole);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.btnPostUsers);
            this.Controls.Add(this.lblContract);
            this.Controls.Add(this.picLogo);
            this.ForeColor = System.Drawing.SystemColors.WindowText;
            this.Name = "ActionPane1";
            this.Size = new System.Drawing.Size(228, 705);
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.PictureBox picLogo;
        private System.Windows.Forms.Label lblContract;
        public System.Windows.Forms.Button btnPostUsers;
        public System.Windows.Forms.Label label1;
        public System.Windows.Forms.Label label2;
        private System.Windows.Forms.ComboBox cboRole;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.ErrorProvider errorProvider1;
        private System.Windows.Forms.Label lblRecordCnt;
        private System.Windows.Forms.Label lblBatch;
        private System.Windows.Forms.ComboBox cboCompany;
        public System.Windows.Forms.Button btnReset;
        private System.Windows.Forms.Label lblResetInfo;
        private System.Windows.Forms.Label lblVersion;
        private System.Windows.Forms.Timer tmrAlertCell;
        private System.Windows.Forms.Label lblAppName;
    }
}
