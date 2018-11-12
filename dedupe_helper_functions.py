# Dedupe helper functions
import dedupe as dd
import pandas as pd
import os
import time
import numpy as np

def dedupe_initialise(data_frame, fields, settings_file, training_file, sample_size = 15000):
    """
    Takes a data dictionary and field definitions and creates a Dedupe object.

    depends:
        pandas as pd
        dedupe as dd

    params:
        data: a pandas data frame of all the records to be deduped
        fields: a list of dicts, where each dict describes a field that the model should inspect

    returns:
        deduper: a Dedupe object
    """

    # Check to see if an initialised model has already been saved.
    # If so, load the initialised model. If not, initialise a new model using the fields list supplied.
    if os.path.exists(settings_file):
        print(f'Reading pre-trained model from {settings_file}...')
        with open(settings_file, 'rb') as f:
            deduper = dd.StaticDedupe(f)
            print('Done')
            return deduper
    else:
        print('Dedupe object for active learning initialised.')
        deduper = dd.Dedupe(fields)

    # Convert data frame into dict as required by Dedupe
    df_nones = data_frame.where(pd.notnull(data_frame), None) # NaN must be converted to 'None'
    data = df_nones.to_dict("index") # convert to list of record dicts

    # Create training sample pairs from provided data
    deduper.sample(data, sample_size)

    # Load existing training file if it exists
    if os.path.exists(training_file):
        print('reading labeled examples from ', training_file)
        with open(training_file, 'rb') as f:
            deduper.readTraining(f)

    return deduper

def run_deduper(deduper, data_frame, settings_file, training_file, recall_weight = 1):
    """
    Given a deduper object and a dataset, this function trains the model and
    predicts which records are duplicates.

    depends:
        dedupe as dd
        pandas as pd
        time

    params:
        deduper: a Dedupe or StaticDedupe object
        data_frame: a pandas data frame where each row is a record to be deduped
        settings_file: a string giving the path where the settings should be written
        training_file: a string giving the path where the labelled training examples should be written
        recall_weight: a number indicating how much to privilege recall over precision.

    returns:
        deduper: the trained Dedupe object
        matches: a list of tuples giving record ids of duplicates and confidence scores
    """

    # Convert data frame into dict as required by Dedupe
    df_nones = data_frame.where(pd.notnull(data_frame), None) # NaN must be converted to 'None'
    data = df_nones.to_dict("index") # convert to list of record dicts
    
    # If the model is untrained (i.e. if it has not been loaded from a saved 'settings file'),
    # then train it:
    if type(deduper) != dd.StaticDedupe:
        
        # Train the model
        print("Active Dedupe object found. Now training model...")
        start = time.perf_counter()
        deduper.train()
        end = time.perf_counter()
        print(f"Training complete. It took {end - start:.3f} seconds.")

        print("Saving training data and trained parameters...")
        # Save the training examples
        with open(training_file, 'w') as tf:
            deduper.writeTraining(tf)
            print(f'Training data written to {training_file}.')

        # Save the model parameters
        with open(settings_file, 'wb') as sf:
            deduper.writeSettings(sf)
            print(f'Trained parameters written to {settings_file}.')

    # Calculate threshold for matches
    print(f"Computing threshold based on a recall weighting of {recall_weight}.")
    start = time.perf_counter()
    threshold = deduper.threshold(data, recall_weight = 1)
    end = time.perf_counter()
    print(f"Computation complete. Threshold = {threshold}. It took {end - start:.3f} seconds.")

    # Compute the matches
    print("Clustering...")
    start = time.perf_counter()
    matches = deduper.match(data, threshold)
    end = time.perf_counter()
    print(f"Clustering complete. {len(matches)} clusters found. It took {end - start:.3f} seconds.")

    return deduper, matches

def save_clusters(matches, data_frame, output_file):
    """
    Given a list of cluster tuples from a Dedupe object, and the original data frame
    on which the model was trained, this function outputs a data frame and saves a csv
    of the cluster assignments for each record/row.

    depends:
        pandas as pd
        dedupe as dd
        numpy as np

    params:
        matches: a list of tuples, returned by Dedupe.matches()
        data_frame: the original data frame on which the model was trained.
        output_file: a string; the path where the csv will be written

    returns:
        data_frame: the original data frame with additional information from the model
    """

    # Add new columns to data frame
    data_frame['cluster'] = np.nan
    data_frame['confidence'] = np.nan

    # Loop through matches, update relevant rows
    for counter, match in enumerate(matches):
        data_frame.loc[match[0], 'cluster'] = int(counter)
        data_frame.loc[match[0], 'confidence'] = match[1]

    # Write csv
    print(f'Writing clustered data to {output_file}...')
    with open(output_file, 'w', encoding='utf-8') as out:
        data_frame.to_csv(out)
    
    print('Done!')

    return data_frame
