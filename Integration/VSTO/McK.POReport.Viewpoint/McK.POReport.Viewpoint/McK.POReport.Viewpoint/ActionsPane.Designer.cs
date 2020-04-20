namespace McK.POReport.Viewpoint
{
    [System.ComponentModel.ToolboxItemAttribute(false)]
    partial class ActionsPane
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
            this.picLogo = new System.Windows.Forms.PictureBox();
            this.label2 = new System.Windows.Forms.Label();
            this.lblVersion = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.btnGetPOs = new System.Windows.Forms.Button();
            this.cboCompany = new System.Windows.Forms.ComboBox();
            this.label3 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.label6 = new System.Windows.Forms.Label();
            this.label7 = new System.Windows.Forms.Label();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.txtPOFrom = new System.Windows.Forms.TextBox();
            this.txtPOTo = new System.Windows.Forms.TextBox();
            this.txtDateFrom = new System.Windows.Forms.MaskedTextBox();
            this.txtDateTo = new System.Windows.Forms.MaskedTextBox();
            this.btnCopyOffline = new System.Windows.Forms.Button();
            this.saveFileDialog1 = new System.Windows.Forms.SaveFileDialog();
            this.btnEmail = new System.Windows.Forms.Button();
            this.tmrRestoreButtonText = new System.Windows.Forms.Timer(this.components);
            this.btnRefresh = new System.Windows.Forms.Button();
            this.openFileDialog1 = new System.Windows.Forms.OpenFileDialog();
            this.openFileDialog2 = new System.Windows.Forms.OpenFileDialog();
            this.lblAppName = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            this.SuspendLayout();
            // 
            // picLogo
            // 
            this.picLogo.BackgroundImage = global::McK.POReport.Viewpoint.Properties.Resources.McKinstry_Logo_Sm;
            this.picLogo.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.picLogo.Location = new System.Drawing.Point(3, 3);
            this.picLogo.Name = "picLogo";
            this.picLogo.Size = new System.Drawing.Size(99, 45);
            this.picLogo.TabIndex = 2;
            this.picLogo.TabStop = false;
            // 
            // label2
            // 
            this.label2.BackColor = System.Drawing.Color.Transparent;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.Location = new System.Drawing.Point(-7, 51);
            this.label2.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(137, 22);
            this.label2.TabIndex = 39;
            this.label2.Text = "McK PO Report";
            this.label2.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.label2.UseMnemonic = false;
            // 
            // lblVersion
            // 
            this.lblVersion.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblVersion.Location = new System.Drawing.Point(6, 99);
            this.lblVersion.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblVersion.Name = "lblVersion";
            this.lblVersion.Size = new System.Drawing.Size(105, 18);
            this.lblVersion.TabIndex = 41;
            this.lblVersion.Text = "v1.0.0.0";
            this.lblVersion.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.lblVersion.UseCompatibleTextRendering = true;
            this.lblVersion.UseMnemonic = false;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(3, 131);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(62, 15);
            this.label1.TabIndex = 42;
            this.label1.Text = "Company:";
            // 
            // btnGetPOs
            // 
            this.btnGetPOs.Location = new System.Drawing.Point(7, 426);
            this.btnGetPOs.Name = "btnGetPOs";
            this.btnGetPOs.Size = new System.Drawing.Size(100, 55);
            this.btnGetPOs.TabIndex = 5;
            this.btnGetPOs.Text = "Get PO(s)";
            this.btnGetPOs.UseVisualStyleBackColor = true;
            this.btnGetPOs.Click += new System.EventHandler(this.btnGetPOs_Click);
            this.btnGetPOs.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            // 
            // cboCompany
            // 
            this.cboCompany.BackColor = System.Drawing.SystemColors.Info;
            this.cboCompany.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboCompany.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboCompany.DropDownWidth = 200;
            this.cboCompany.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.cboCompany.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboCompany.FormattingEnabled = true;
            this.cboCompany.Location = new System.Drawing.Point(6, 157);
            this.cboCompany.Name = "cboCompany";
            this.cboCompany.Size = new System.Drawing.Size(118, 22);
            this.cboCompany.TabIndex = 0;
            this.cboCompany.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItem);
            this.cboCompany.SelectedIndexChanged += new System.EventHandler(this.cboCompany_SelectedIndexChanged);
            this.cboCompany.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.cboCompany.Validating += new System.ComponentModel.CancelEventHandler(this.cboCompany_Validating);
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label3.Location = new System.Drawing.Point(4, 307);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(98, 15);
            this.label3.TabIndex = 45;
            this.label3.Text = "Start Order Date:";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label4.Location = new System.Drawing.Point(4, 361);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(95, 15);
            this.label4.TabIndex = 46;
            this.label4.Text = "End Order Date:";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label6.Location = new System.Drawing.Point(3, 249);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(52, 15);
            this.label6.TabIndex = 48;
            this.label6.Text = "End PO:";
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label7.Location = new System.Drawing.Point(3, 191);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(55, 15);
            this.label7.TabIndex = 49;
            this.label7.Text = "Start PO:";
            // 
            // errorProvider1
            // 
            this.errorProvider1.ContainerControl = this;
            // 
            // txtPOFrom
            // 
            this.txtPOFrom.BackColor = System.Drawing.SystemColors.Info;
            this.txtPOFrom.Location = new System.Drawing.Point(6, 214);
            this.txtPOFrom.Name = "txtPOFrom";
            this.txtPOFrom.Size = new System.Drawing.Size(118, 20);
            this.txtPOFrom.TabIndex = 1;
            this.txtPOFrom.Click += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtPOFrom.TextChanged += new System.EventHandler(this.txtPOFrom_TextChanged);
            this.txtPOFrom.Enter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtPOFrom.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.txtPOFrom.MouseEnter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtPOFrom.Validating += new System.ComponentModel.CancelEventHandler(this.txtPOFrom_Validating);
            // 
            // txtPOTo
            // 
            this.txtPOTo.BackColor = System.Drawing.SystemColors.Info;
            this.txtPOTo.Location = new System.Drawing.Point(6, 272);
            this.txtPOTo.Name = "txtPOTo";
            this.txtPOTo.Size = new System.Drawing.Size(118, 20);
            this.txtPOTo.TabIndex = 2;
            this.txtPOTo.Click += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtPOTo.Enter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtPOTo.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.txtPOTo.MouseEnter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtPOTo.Validating += new System.ComponentModel.CancelEventHandler(this.txtPOTo_Validating);
            // 
            // txtDateFrom
            // 
            this.txtDateFrom.BackColor = System.Drawing.SystemColors.Info;
            this.txtDateFrom.Location = new System.Drawing.Point(7, 328);
            this.txtDateFrom.Mask = "00/00/00";
            this.txtDateFrom.Name = "txtDateFrom";
            this.txtDateFrom.Size = new System.Drawing.Size(67, 20);
            this.txtDateFrom.TabIndex = 3;
            this.txtDateFrom.Click += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtDateFrom.TextChanged += new System.EventHandler(this.txtDateFrom_TextChanged);
            this.txtDateFrom.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.txtDateFrom.MouseEnter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            // 
            // txtDateTo
            // 
            this.txtDateTo.BackColor = System.Drawing.SystemColors.Info;
            this.txtDateTo.Location = new System.Drawing.Point(7, 388);
            this.txtDateTo.Mask = "00/00/00";
            this.txtDateTo.Name = "txtDateTo";
            this.txtDateTo.Size = new System.Drawing.Size(68, 20);
            this.txtDateTo.TabIndex = 4;
            this.txtDateTo.Click += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtDateTo.Enter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtDateTo.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.txtDateTo.MouseEnter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtDateTo.Validating += new System.ComponentModel.CancelEventHandler(this.TextBoxes_TextChanged);
            // 
            // btnCopyOffline
            // 
            this.btnCopyOffline.Enabled = false;
            this.btnCopyOffline.Location = new System.Drawing.Point(7, 548);
            this.btnCopyOffline.Name = "btnCopyOffline";
            this.btnCopyOffline.Size = new System.Drawing.Size(100, 55);
            this.btnCopyOffline.TabIndex = 7;
            this.btnCopyOffline.Text = "Copy Offline";
            this.btnCopyOffline.UseVisualStyleBackColor = true;
            this.btnCopyOffline.Click += new System.EventHandler(this.btnCopyOffline_Click);
            // 
            // btnEmail
            // 
            this.btnEmail.Enabled = false;
            this.btnEmail.Location = new System.Drawing.Point(7, 609);
            this.btnEmail.Name = "btnEmail";
            this.btnEmail.Size = new System.Drawing.Size(100, 55);
            this.btnEmail.TabIndex = 8;
            this.btnEmail.Text = "Send via Email";
            this.btnEmail.UseVisualStyleBackColor = true;
            this.btnEmail.Click += new System.EventHandler(this.btnEmail_Click);
            // 
            // tmrRestoreButtonText
            // 
            this.tmrRestoreButtonText.Interval = 1307;
            this.tmrRestoreButtonText.Tick += new System.EventHandler(this.tmrRestoreButtonText_Tick);
            // 
            // btnRefresh
            // 
            this.btnRefresh.Location = new System.Drawing.Point(7, 487);
            this.btnRefresh.Name = "btnRefresh";
            this.btnRefresh.Size = new System.Drawing.Size(100, 55);
            this.btnRefresh.TabIndex = 6;
            this.btnRefresh.Text = "Refresh Existing Worksheet(s)";
            this.btnRefresh.UseVisualStyleBackColor = true;
            this.btnRefresh.Click += new System.EventHandler(this.btnRefresh_Click);
            // 
            // openFileDialog1
            // 
            this.openFileDialog1.FileName = "openFileDialog1";
            // 
            // openFileDialog2
            // 
            this.openFileDialog2.FileName = "openFileDialog2";
            // 
            // lblAppName
            // 
            this.lblAppName.BackColor = System.Drawing.Color.Black;
            this.lblAppName.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblAppName.ForeColor = System.Drawing.Color.Yellow;
            this.lblAppName.Location = new System.Drawing.Point(6, 74);
            this.lblAppName.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblAppName.Name = "lblAppName";
            this.lblAppName.Size = new System.Drawing.Size(105, 23);
            this.lblAppName.TabIndex = 50;
            this.lblAppName.Text = "(Upgrade)";
            this.lblAppName.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.lblAppName.UseMnemonic = false;
            // 
            // ActionsPane
            // 
            this.Controls.Add(this.lblAppName);
            this.Controls.Add(this.btnRefresh);
            this.Controls.Add(this.btnEmail);
            this.Controls.Add(this.btnCopyOffline);
            this.Controls.Add(this.txtDateTo);
            this.Controls.Add(this.txtDateFrom);
            this.Controls.Add(this.txtPOTo);
            this.Controls.Add(this.txtPOFrom);
            this.Controls.Add(this.label7);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.cboCompany);
            this.Controls.Add(this.btnGetPOs);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.lblVersion);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.picLogo);
            this.Name = "ActionsPane";
            this.Size = new System.Drawing.Size(130, 686);
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.PictureBox picLogo;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label lblVersion;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Button btnGetPOs;
        private System.Windows.Forms.ComboBox cboCompany;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.ErrorProvider errorProvider1;
        internal System.Windows.Forms.TextBox txtPOTo;
        internal System.Windows.Forms.TextBox txtPOFrom;
        private System.Windows.Forms.MaskedTextBox txtDateFrom;
        private System.Windows.Forms.MaskedTextBox txtDateTo;
        private System.Windows.Forms.Button btnCopyOffline;
        private System.Windows.Forms.SaveFileDialog saveFileDialog1;
        private System.Windows.Forms.Button btnEmail;
        private System.Windows.Forms.Timer tmrRestoreButtonText;
        private System.Windows.Forms.Button btnRefresh;
        private System.Windows.Forms.OpenFileDialog openFileDialog1;
        private System.Windows.Forms.OpenFileDialog openFileDialog2;
        internal System.Windows.Forms.Label lblAppName;
    }
}
