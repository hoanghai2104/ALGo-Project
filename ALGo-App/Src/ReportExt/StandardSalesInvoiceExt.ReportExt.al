reportextension 50102 StandardSalesInvoiceExt extends "Standard Sales - Invoice"
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
            column(Remise_articles; "% Remise articles")
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
            column(Nom_du_Proprietaire; Header.GetNomduProprietaire()) { }
            column(PrepaymentAmount; GetPrepaymentAmount()) { }
            column(Cust_Contact_Type; this.getCustType("Sell-to Customer No."))
            {
            }
        }
    }

    local procedure GetPrepaymentAmount(): Decimal
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", Header."No.");
        SalesInvLine.SetRange("Prepayment Line", true);
        SalesInvLine.CalcSums("Amount Including VAT");
        exit(Abs(SalesInvLine."Amount Including VAT"));
    end;

    local procedure getCustType(CustNo: code[20]): Integer
    var
        customer: Record Customer;
    begin
        if customer.get(CustNo) then
            exit(customer."Contact Type".AsInteger());
    end;
}