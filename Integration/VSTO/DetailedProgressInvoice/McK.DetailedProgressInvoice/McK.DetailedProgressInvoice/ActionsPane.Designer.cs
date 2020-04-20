namespace McK.JBDetailedProgressInvoice.Viewpoint
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
            this.lblEnvironment = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.btnGetInvoices = new System.Windows.Forms.Button();
            this.cboCompany = new System.Windows.Forms.ComboBox();
            this.label3 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.label6 = new System.Windows.Forms.Label();
            this.label7 = new System.Windows.Forms.Label();
            this.cboSortBy = new System.Windows.Forms.ComboBox();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.txtInvoiceFrom = new System.Windows.Forms.TextBox();
            this.txtInvoiceTo = new System.Windows.Forms.TextBox();
            this.txtDateFrom = new System.Windows.Forms.MaskedTextBox();
            this.txtDateTo = new System.Windows.Forms.MaskedTextBox();
            this.btnCopyOffline = new System.Windows.Forms.Button();
            this.saveFileDialog1 = new System.Windows.Forms.SaveFileDialog();
            this.btnEmail = new System.Windows.Forms.Button();
            this.tmrRestoreButtonText = new System.Windows.Forms.Timer(this.components);
            this.timer1 = new System.Windows.Forms.Timer(this.components);
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            this.SuspendLayout();
            // 
            // picLogo
            // 
            this.picLogo.BackgroundImage = global::McK.JBDetailedProgressInvoice.Viewpoint.Properties.Resources.McKinstry_Logo_Sm;
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
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 6.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.Location = new System.Drawing.Point(-3, 53);
            this.label2.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(133, 37);
            this.label2.TabIndex = 39;
            this.label2.Text = "JB Detailed Progress Invoice";
            this.label2.TextAlign = System.Drawing.ContentAlignment.TopCenter;
            this.label2.UseMnemonic = false;
            // 
            // lblVersion
            // 
            this.lblVersion.Font = new System.Drawing.Font("Microsoft Sans Serif", 6.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblVersion.Location = new System.Drawing.Point(6, 90);
            this.lblVersion.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblVersion.Name = "lblVersion";
            this.lblVersion.Size = new System.Drawing.Size(53, 15);
            this.lblVersion.TabIndex = 41;
            this.lblVersion.Text = "v1.1.1.8";
            this.lblVersion.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.lblVersion.UseCompatibleTextRendering = true;
            this.lblVersion.UseMnemonic = false;
            // 
            // lblEnvironment
            // 
            this.lblEnvironment.BackColor = System.Drawing.Color.Transparent;
            this.lblEnvironment.Font = new System.Drawing.Font("Microsoft Sans Serif", 6.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblEnvironment.Location = new System.Drawing.Point(67, 93);
            this.lblEnvironment.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblEnvironment.Name = "lblEnvironment";
            this.lblEnvironment.Size = new System.Drawing.Size(39, 21);
            this.lblEnvironment.TabIndex = 40;
            this.lblEnvironment.Text = "(Dev)";
            this.lblEnvironment.UseMnemonic = false;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(2, 125);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(62, 15);
            this.label1.TabIndex = 42;
            this.label1.Text = "Company:";
            // 
            // btnGetInvoices
            // 
            this.btnGetInvoices.Location = new System.Drawing.Point(6, 534);
            this.btnGetInvoices.Name = "btnGetInvoices";
            this.btnGetInvoices.Size = new System.Drawing.Size(100, 55);
            this.btnGetInvoices.TabIndex = 43;
            this.btnGetInvoices.Text = "Get Invoice(s)";
            this.btnGetInvoices.UseVisualStyleBackColor = true;
            this.btnGetInvoices.Click += new System.EventHandler(this.btnGetInvoices_Click);
            this.btnGetInvoices.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
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
            this.cboCompany.Location = new System.Drawing.Point(5, 151);
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
            this.label3.Location = new System.Drawing.Point(3, 325);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(93, 15);
            this.label3.TabIndex = 45;
            this.label3.Text = "Start Bill Month:";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label4.Location = new System.Drawing.Point(2, 391);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(90, 15);
            this.label4.TabIndex = 46;
            this.label4.Text = "End Bill Month:";
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label5.Location = new System.Drawing.Point(3, 461);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(47, 15);
            this.label5.TabIndex = 47;
            this.label5.Text = "Sort ßy:";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label6.Location = new System.Drawing.Point(2, 256);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(73, 15);
            this.label6.TabIndex = 48;
            this.label6.Text = "End Invoice:";
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label7.Location = new System.Drawing.Point(2, 187);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(76, 15);
            this.label7.TabIndex = 49;
            this.label7.Text = "Start Invoice:";
            // 
            // cboSortBy
            // 
            this.cboSortBy.AutoCompleteCustomSource.AddRange(new string[] {
            "B-Bill",
            "I-Invoice"});
            this.cboSortBy.AutoCompleteMode = System.Windows.Forms.AutoCompleteMode.SuggestAppend;
            this.cboSortBy.AutoCompleteSource = System.Windows.Forms.AutoCompleteSource.ListItems;
            this.cboSortBy.BackColor = System.Drawing.SystemColors.Info;
            this.cboSortBy.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboSortBy.DropDownHeight = 40;
            this.cboSortBy.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboSortBy.DropDownWidth = 15;
            this.cboSortBy.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.cboSortBy.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboSortBy.FormattingEnabled = true;
            this.cboSortBy.IntegralHeight = false;
            this.cboSortBy.ItemHeight = 17;
            this.cboSortBy.Items.AddRange(new object[] {
            "B-Bill",
            "I-Invoice"});
            this.cboSortBy.Location = new System.Drawing.Point(6, 488);
            this.cboSortBy.MaxDropDownItems = 4;
            this.cboSortBy.Name = "cboSortBy";
            this.cboSortBy.Size = new System.Drawing.Size(77, 23);
            this.cboSortBy.TabIndex = 5;
            this.cboSortBy.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItem);
            // 
            // errorProvider1
            // 
            this.errorProvider1.ContainerControl = this;
            // 
            // txtInvoiceFrom
            // 
            this.txtInvoiceFrom.BackColor = System.Drawing.SystemColors.Info;
            this.txtInvoiceFrom.Location = new System.Drawing.Point(5, 214);
            this.txtInvoiceFrom.Name = "txtInvoiceFrom";
            this.txtInvoiceFrom.Size = new System.Drawing.Size(118, 20);
            this.txtInvoiceFrom.TabIndex = 3;
            this.txtInvoiceFrom.Click += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtInvoiceFrom.TextChanged += new System.EventHandler(this.txtStartInvoice_TextChanged);
            this.txtInvoiceFrom.Enter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtInvoiceFrom.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.txtInvoiceFrom.MouseEnter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtInvoiceFrom.Validating += new System.ComponentModel.CancelEventHandler(this.txtStartInvoice_Validating);
            // 
            // txtInvoiceTo
            // 
            this.txtInvoiceTo.BackColor = System.Drawing.SystemColors.Info;
            this.txtInvoiceTo.Location = new System.Drawing.Point(5, 283);
            this.txtInvoiceTo.Name = "txtInvoiceTo";
            this.txtInvoiceTo.Size = new System.Drawing.Size(118, 20);
            this.txtInvoiceTo.TabIndex = 4;
            this.txtInvoiceTo.Click += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtInvoiceTo.Enter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtInvoiceTo.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.txtInvoiceTo.MouseEnter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtInvoiceTo.Validating += new System.ComponentModel.CancelEventHandler(this.txtEndInvoice_Validating);
            // 
            // txtDateFrom
            // 
            this.txtDateFrom.BackColor = System.Drawing.SystemColors.Info;
            this.txtDateFrom.Location = new System.Drawing.Point(6, 346);
            this.txtDateFrom.Mask = "00/00";
            this.txtDateFrom.Name = "txtDateFrom";
            this.txtDateFrom.Size = new System.Drawing.Size(44, 20);
            this.txtDateFrom.TabIndex = 1;
            this.txtDateFrom.Click += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtDateFrom.TextChanged += new System.EventHandler(this.txtStartBillMonth_TextChanged);
            this.txtDateFrom.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.txtDateFrom.MouseEnter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            // 
            // txtDateTo
            // 
            this.txtDateTo.BackColor = System.Drawing.SystemColors.Info;
            this.txtDateTo.Location = new System.Drawing.Point(5, 418);
            this.txtDateTo.Mask = "00/00";
            this.txtDateTo.Name = "txtDateTo";
            this.txtDateTo.Size = new System.Drawing.Size(45, 20);
            this.txtDateTo.TabIndex = 2;
            this.txtDateTo.Click += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtDateTo.Enter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtDateTo.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.txtDateTo.MouseEnter += new System.EventHandler(this.txtBoxHighlight_On_Enter);
            this.txtDateTo.Validating += new System.ComponentModel.CancelEventHandler(this.TextBoxes_TextChanged);
            // 
            // btnCopyOffline
            // 
            this.btnCopyOffline.Enabled = false;
            this.btnCopyOffline.Location = new System.Drawing.Point(6, 605);
            this.btnCopyOffline.Name = "btnCopyOffline";
            this.btnCopyOffline.Size = new System.Drawing.Size(100, 55);
            this.btnCopyOffline.TabIndex = 50;
            this.btnCopyOffline.Text = "Copy Offline";
            this.btnCopyOffline.UseVisualStyleBackColor = true;
            this.btnCopyOffline.Click += new System.EventHandler(this.btnCopyOffline_Click);
            // 
            // btnEmail
            // 
            this.btnEmail.Enabled = false;
            this.btnEmail.Location = new System.Drawing.Point(6, 676);
            this.btnEmail.Name = "btnEmail";
            this.btnEmail.Size = new System.Drawing.Size(100, 55);
            this.btnEmail.TabIndex = 51;
            this.btnEmail.Text = "Send via Email";
            this.btnEmail.UseVisualStyleBackColor = true;
            this.btnEmail.Click += new System.EventHandler(this.btnEmail_Click);
            // 
            // tmrRestoreButtonText
            // 
            this.tmrRestoreButtonText.Interval = 1307;
            this.tmrRestoreButtonText.Tick += new System.EventHandler(this.tmrRestoreButtonText_Tick);
            // 
            // timer1
            // 
            this.timer1.Interval = 24000;
            this.timer1.Tick += new System.EventHandler(this.timer1_Tick);
            // 
            // ActionsPane
            // 
            this.Controls.Add(this.btnEmail);
            this.Controls.Add(this.btnCopyOffline);
            this.Controls.Add(this.txtDateTo);
            this.Controls.Add(this.txtDateFrom);
            this.Controls.Add(this.txtInvoiceTo);
            this.Controls.Add(this.txtInvoiceFrom);
            this.Controls.Add(this.cboSortBy);
            this.Controls.Add(this.label7);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.cboCompany);
            this.Controls.Add(this.btnGetInvoices);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.lblVersion);
            this.Controls.Add(this.lblEnvironment);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.picLogo);
            this.Name = "ActionsPane";
            this.Size = new System.Drawing.Size(133, 739);
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.PictureBox picLogo;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label lblVersion;
        internal System.Windows.Forms.Label lblEnvironment;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Button btnGetInvoices;
        private System.Windows.Forms.ComboBox cboCompany;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.ComboBox cboSortBy;
        private System.Windows.Forms.ErrorProvider errorProvider1;
        internal System.Windows.Forms.TextBox txtInvoiceTo;
        internal System.Windows.Forms.TextBox txtInvoiceFrom;
        private System.Windows.Forms.MaskedTextBox txtDateFrom;
        private System.Windows.Forms.MaskedTextBox txtDateTo;
        private System.Windows.Forms.Button btnCopyOffline;
        private System.Windows.Forms.SaveFileDialog saveFileDialog1;
        private System.Windows.Forms.Button btnEmail;
        private System.Windows.Forms.Timer tmrRestoreButtonText;
        private System.Windows.Forms.Timer timer1;
    }
}
