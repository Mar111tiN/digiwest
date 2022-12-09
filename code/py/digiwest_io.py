import pandas as pd
import numpy as np
import os

from script_utils import show_output, load_config
from stats import med_center, cols2scaled, norm2control


def extract_data(excel_file, *, sheet="", config, **kwargs):
    '''
    extract the data and tidy
    '''
    if not excel_file.startswith("/"):
        excel_file = os.path.join(config['paths']['data_path'], excel_file)
    # shorthand config
    ec = config['extract_data']
    if not sheet:
        sheet = ec['excel_sheet']
    show_output(f"Loading DigiWest data from {excel_file}")
    # load the data
    df = pd.read_excel(excel_file, sheet_name=sheet, **kwargs).set_index("Analyte").T.reset_index().rename({"index":"Analyte"}, axis=1)
    
    factor_levels = ec['factors']
    # + extract the conditions to sample_cols using factor_levels and the extract pattern
    sample_cols = list(factor_levels.keys())   
    factor_extract_pattern = ec['extract_pattern']

    df.loc[:, sample_cols] =  df['Analyte'].str.extract(factor_extract_pattern)
    # stack the Analytes --> tidy data
    df = df.dropna(axis=0, subset = sample_cols[0]).drop("Analyte", axis=1).set_index(sample_cols).stack().reset_index().rename({0:"MFI"}, axis=1).sort_values(sample_cols, ascending=False).reset_index(drop=True)
    # extract the Analyte info
    # first the cleanup
    sig_pat = r" Signal (TK )?# [0-9]+$"
    syk_pat = r"/Syk Tyr[0-9]+ "
    df.loc[:, 'Analyte'] = df['Analyte'].str.replace(sig_pat, "", regex=True).str.replace(r"\(.*\)", "", regex=True)
    # then the extracts
    full_pattern = r"^(?P<Protein>.*?)(?: - phospho_(?P<Phospho>[A-Za-z0-9/]+))? Peak(?P<Peak>[12])"
    df.loc[:, ["Protein", 'Phospho', 'Peak']] = df['Analyte'].str.replace(syk_pat, " ", regex=True).str.extract(full_pattern)
    # for falty extracts, just use the 'Analyte'
    df.loc[df['Protein'] != df['Protein'], 'Protein'] = df.loc[df['Protein'] != df['Protein'], 'Analyte']
    
    if ec['remove_zz']: # remove zz
        df = df.loc[~df['Protein'].str.startswith("zz"), :]
    # count percentage of NA == 33 values
    df.loc[:, 'NAvalues'] = df.groupby('Analyte')['MFI'].transform(lambda x: sum(x == 33) / sum(x >0))
    # concat column info

    # recollect the Analyte Info into Analyte
    df.loc[:, 'AnalyteOrg'] = df['Analyte']
    df.loc[:, 'Analyte'] = df['Protein'].str[0].str.upper() + df['Protein'].str[1:]

    # convert the analytes to greek format
    if ec['format_analytes']:
        # convert to greek
        df.loc[:, 'Analyte'] = df['Analyte'].str.replace("alpha", "α").str.replace("beta", "β").str.replace("gamma", "γ").str.replace("delta", "δ").str.replace("kappa", "κ")
        # remove excessive spaces
        df.loc[:, 'Analyte'] = df.loc[:, "Analyte"].str.replace(" ", "")
        # recover spaces for p110 etc
        df.loc[:, 'Analyte'] = df.loc[:, "Analyte"].str.replace(r"(p[0-9]+)", r" \1", regex=True).str.replace("Za p", "Zap")
        
    # remove the total Protein row
    df = df.loc[df['Analyte'] != "TotalProtein", :]
    
    df.loc[df['Peak'].astype(int) > 1, 'Analyte'] = df['Analyte'] + "(2)"
    df.loc[df['Phospho'] == df['Phospho'], "Analyte"] = df['Analyte'] + " | " + df['Phospho']
    df.loc[:,  'Phospho'] = df['Phospho'].fillna("")
    
   
    df['Sample'] = ""
    for fct in factor_levels:
        df[fct] = df[fct].str.replace(" ", "")
        # recollect the sample conditions into Sample Column
        df.loc[:, 'Sample'] = df['Sample'] + "_" + df[fct]
        # sort columns by samples
        
        # if factor levels are given in the config, sort by them
        if factor_levels[fct] == "all":
            df[fct] = pd.Categorical(df[fct])
        else:
            df[fct] = pd.Categorical(df[fct], factor_levels[fct])
    df['Sample'] = df['Sample'].str.strip("_")
    cols = ['Sample'] + sample_cols + ['Analyte', 'Protein', 'Phospho', 'Peak', 'NAvalues', 'MFI']    
    df = df.loc[:, cols].sort_values(sample_cols)   
    return df


def digiWest2df(excel_file, excel_sheet="", output_table="", config_file="", config_path="", **kwargs):
    '''
    takes a digiwest raw data file and extracts the data
    also normalizations are performed according to arguments
    '''

    config = load_config(config_file, config_path=config_path)
    # load the data
    df = extract_data(excel_file, sheet=excel_sheet, config=config)
 
    ##############################
    # normalizations
    nsc = config['normscale']
    # load the sample_cols into nsc_dict
    nsc['sample_cols'] = list(config['extract_data']['factors'].keys())
    # get the added columns for later output
    scale_cols = []
    
    # median-normalize across samples
    scale_cols.append(sample_centered_col:="medMFI")
    df = med_center(df, centered_col_name=sample_centered_col, **nsc)
    # log_transform
    scale_cols.append(log_col:="logMFI")
    df.loc[:, log_col] = np.log2(df[sample_centered_col])

    # norm-scale
    df, scaled_cols = cols2scaled(df, scale_cols=scale_cols, group_col="Analyte")

    # both subtraction (min) and divivion (div)
    df, norm_cols = norm2control(df, **nsc)

    if output_table:
        if not ".csv" in output_table:
            output_table += ".csv"
        df.to_csv(os.path.join(config['paths']['tables_path'], output_table), sep="\t", index=False)
    
    return df.reset_index(drop=True), nsc