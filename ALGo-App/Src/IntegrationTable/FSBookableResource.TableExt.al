namespace Marechal.DataverseMapping;
using Microsoft.Integration.DynamicsFieldService;
tableextension 50123 FSBookableResource extends "FS Bookable Resource"
{
    fields
    {
        // Add changes to table fields here
        field(50100; phma_Codetechnicien; Text[100])
        {
            ExternalName = 'phma_codetechnicien';
            ExternalType = 'String';
            Description = '';
            Caption = 'Code technicien';
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

}