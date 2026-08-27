reportextension 50100 StandardSalesQuoteExt extends "Standard Sales - Quote"
{
    dataset
    {
        add(Line)
        {
            column(DescriptionSupp; "Description Supp.") { }
            column(OB_Line; "% OB")
            {
                DecimalPlaces = 2;
            }
            column(Word_Ob_Line; ReportFormatHelper.DecimalWordFormat("% OB"))
            {

            }
            column(Remise_articles; "% Remise articles")
            {
                DecimalPlaces = 2;
            }
            column(Word_Remise_articles_line; ReportFormatHelper.DecimalWordFormat("% Remise articles"))
            {

            }
            column(Word_RemiseArticle_OB_line; ReportFormatHelper.DecimalWordFormat("% Remise articles") + ' ' + ReportFormatHelper.DecimalWordFormat("% OB"))
            {

            }
            column(Word_TotalPrice_excl_Rabais; line.Quantity * Line."Unit Price")
            {
                DecimalPlaces = 2;
            }
            column(Quantity_Line_Numeric; Quantity) { }
            column(UnitPrice_Numeric; "Unit Price") { }
            column(LineAmount_Line_Numeric; "Line Amount") { }
            column(VATPct_Line_Numeric; "VAT %") { }
        }

        add(Header)
        {
            column(ReferenceSupp; "Reference Supp.") { }
            column(SoumissionExists; HasSoumission()) { }
            column(Nom_du_Proprietaire; Header.GetNomduProprietaire()) { }
            column(Assigned_User_ID; "Assigned User ID") { }
        }
        addbefore(Totals)
        {
            dataitem(SoumissionHeader; SoumissionHeader)
            {
                DataItemLink = DocumentNo = field("No."), "Document Type" = field("Document Type");
                DataItemLinkReference = Header;
                column(Soumission_ID; "Soumission ID") { }
                column(Customer_ID; "Customer ID") { }
                column(Document_No; DocumentNo) { }
                column(Document_Type; "Document Type") { }
                column(Montant; Montant) { }
                dataitem(SoumissionLine; SoumissionLine)
                {
                    DataItemLink = "Soumission ID" = field("Soumission ID");
                    DataItemLinkReference = SoumissionHeader;
                    column(SoumissionLine_ID; "Soumission ID") { }
                    column(Line_No; "Line No") { }
                    column(Type; Type) { }
                    column(No; No) { }
                    column(Designation; Designation) { }
                    column(Description_Supp; "Description Supp.") { }
                    column(Designation_Description_Supp; Designation + ' - ' + "Description Supp.") { }
                    column(Code_RPLP; "Code RPLP") { }
                    column(Totalisation; Totalisation) { }
                    column(Quantity; Quantity) { }
                    column(Unit_Price; "Unit Price (base)")
                    {
                        DecimalPlaces = 2;
                    }
                    column(Remise; Remise) { }
                    column(word_Remise; ReportFormatHelper.DecimalWordFormat(Remise))
                    {

                    }
                    column(OB; "% OB") { }
                    column(Word_OB; ReportFormatHelper.DecimalWordFormat("% OB"))
                    {

                    }
                    column(Word_Remise_OB; ReportFormatHelper.DecimalWordFormat(Remise) + ' ' + ReportFormatHelper.DecimalWordFormat("% OB"))
                    {

                    }
                    column(Prix_Unitaire_net; "Prix Unitaire net")
                    {
                        DecimalPlaces = 2;
                    }
                    column(Montant_net; "Montant net")
                    {
                        DecimalPlaces = 2;
                    }
                    column(Montant_Totalisation; "Montant Totalisation")
                    {
                        DecimalPlaces = 2;
                    }
                    column(Style_Property; "Style Property") { }
                    column(Gras; Gras) { }
                    column(Italique; Italique) { }
                    column("Souligné"; "Souligné") { }
                    trigger OnAfterGetRecord()
                    begin
                        totalVatCalculation();
                    end;

                }
                dataitem(SoumissionVat; Integer)
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column("Total_Excl_VAT_Soumission"; TotalSoumissionLine."Montant net")
                    {
                        AutoFormatExpression = Header."Currency Code";
                        AutoFormatType = 1;
                        DecimalPlaces = 2;
                    }
                    column("Total_VAT_Soumission"; TotalVat)
                    {
                        AutoFormatExpression = Header."Currency Code";
                        AutoFormatType = 1;
                        DecimalPlaces = 2;
                    }
                    column("Total_Incl_VAT_Soumission"; TotalSoumissionLine."Amount Including Vat")
                    {
                        AutoFormatExpression = Header."Currency Code";
                        AutoFormatType = 1;
                        DecimalPlaces = 2;
                    }

                }

            }
        }
    }

    local procedure HasSoumission(): Boolean
    var
        SoumissionRec: Record SoumissionHeader;
        hasSoumissionBoolean: Boolean;
    begin
        SoumissionRec.Reset();
        SoumissionRec.SetRange(DocumentNo, Header."No.");
        SoumissionRec.SetRange("Document Type", Header."Document Type");
        if SoumissionRec.IsEmpty then begin
            hasSoumissionBoolean := false;
        end else begin
            hasSoumissionBoolean := true;
        end;
        exit(hasSoumissionBoolean);
    end;

    procedure totalVatCalculation()
    begin
        TotalSoumissionLine.Reset();
        TotalSoumissionLine.SetRange("Soumission ID", SoumissionLine."Soumission ID");
        TotalSoumissionLine.SetRange(Type, TotalSoumissionLine.Type::Article);
        TotalSoumissionLine.CalcSums("Montant net", "Amount Including Vat");
        TotalVat := TotalSoumissionLine."Amount Including Vat" - TotalSoumissionLine."Montant net";
    end;



    var
        TotalSoumissionLine: Record SoumissionLine;
        ReportFormatHelper: Codeunit ReportFormatHelper;
        TotalVat: Decimal;



}