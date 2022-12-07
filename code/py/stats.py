from script_utils import show_output

def med_center(
    df, 
    col4center="MFI", 
    centered_col_name="", 
    sample_cols=["Sample"], 
    center_func=lambda x: x / x.median(),
    **kwargs
    ):    
    '''
    normalizes a data col across all samples defined by sample_cols
    MFI --> median normalization across samples: medMFI
    '''    
    if not centered_col_name:
        centered_col_name = f"med{col4center}"
    ### apply Median normalization across samples
    df.loc[:, centered_col_name] = df.groupby(sample_cols)[col4center].transform(center_func)  
    return df


# get the medMFI normalized by wo-control per Pop and Stim
def norm2control(df, sample_cols=["Sample"], analyte_cols=['Analyte'], norm2control={
        'controlName': {
            'data_cols': ['medMFI_sc', 'logMFI_sc'],
            'norm_versus': [
                {'Cells': 'non-Treg'},
                {'Treatment': 'Medium'}
            ],
           'operations': ['min']
        }
    }, **kwargs):
    '''
    normalizes data_col to some control
    
    '''
    
    cols_added = []
    for name, norm_dict in norm2control.items():
        show_output(f"Normalizing for {name}")
        
        # extract all info from the norm_dict
        data_cols = norm_dict['data_cols']
        operations = norm_dict['operations']
        norm_cols = [list(norm.keys())[0] for norm in norm_dict['norm_versus']]
        index_cols = [col for col in sample_cols if not col in norm_cols] + analyte_cols
        
        # extract the query string and apply for norm_df
        query = " and ".join([f'{list(data.keys())[0]} == "{list(data.values())[0]}"' for data in norm_dict['norm_versus']])
        norm_df = df.query(query)
        
        # cycle through the data columns
        for data_col in data_cols:
            # add the control values via merge
            df = df.merge(norm_df.loc[:, index_cols + [data_col]].rename({data_col:name}, axis=1))
            for op in operations:
                norm_col_name = f"{data_col}_{op}{name}"
                if op == "min":
                    df[norm_col_name] = df[data_col] - df[name]
                if op == "div":
                    df[norm_col_name] = df[data_col] / df[name]
                cols_added.append(norm_col_name)
                show_output(f"\tAdding {norm_col_name}")
            # remove normalizer
            df = df.drop(name, axis=1)
    return df, cols_added


def cols2scaled(df, scale_cols, group_col="Analyte"):
    '''
    takes a list of cols to be scaled and returns their norm-scaled values
    '''

    ### apply respective 0-normal scaling
    
    scaled_cols = []
    for data_col in scale_cols:
        col = f'{data_col}_sc'
        df.loc[:, col] = df.groupby([group_col])[data_col].transform(lambda x: (x - x.mean()) / x.std())
        scaled_cols.append(col)
    return df, scaled_cols