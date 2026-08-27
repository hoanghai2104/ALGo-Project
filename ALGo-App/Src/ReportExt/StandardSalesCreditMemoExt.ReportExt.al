reportextension 50109 StandardSalesCreditMemoExt extends "Standard Sales - Credit Memo"
{
    dataset
    {
        add(Header)
        {
            column(Nom_du_Proprietaire; Header.GetNomduProprietaire()) { }
        }
    }
}