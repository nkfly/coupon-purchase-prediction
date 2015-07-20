import csv
import random
import numpy
import math
from sklearn.ensemble import RandomForestClassifier
from scipy.spatial.distance import cosine
import operator


def get_all_pref_name(user_list):
    pref_name_dict = {}
    with open(user_list, 'r') as csvfile:
        spamreader = csv.DictReader(csvfile)
        for row in spamreader:
            pref_name_dict[row['PREF_NAME']] = True

    return pref_name_dict

# The information of REG_DATE and WITHDRAW_DATE can be further used
def compose_user_hash_to_vector_dict(user_list):
    user_hash_to_vector_dict = {}
    user_hash_to_pref = {}

    pref_name_dict = get_all_pref_name(user_list)

    with open(user_list, 'r') as csvfile:
        spamreader = csv.DictReader(csvfile)

        for row in spamreader:
            vector = []

            if row['SEX_ID'] == 'f':
                vector.extend([1, 0])
            elif row['SEX_ID'] == 'm':
                vector.extend([0, 1])

            vector.append(int(row['AGE']))

            for pref_name in pref_name_dict:
                if pref_name == row['PREF_NAME']:
                    vector.append(1)
                else:
                    vector.append(0)
            user_hash_to_pref[row['USER_ID_hash']] = row['PREF_NAME']

            user_hash_to_vector_dict[row['USER_ID_hash']] = vector

    return user_hash_to_vector_dict, user_hash_to_pref



# The training set spans the dates 2011-07-01 to 2012-06-23.
# The test set spans the week after the end of the training set, 2012-06-24 to 2012-06-30.

def get_info_from_coupon_list():
    coupon_list = './data/coupon_list_train.csv' # must be train to include all info
    genre_dict = {}
    large_area_dict = {}
    ken_dict = {}
    small_area_dict = {}
    with open(coupon_list, 'r') as csvfile:
        spamreader = csv.DictReader(csvfile)
        for row in spamreader:
            genre_dict[row['GENRE_NAME']] = True
            large_area_dict[row['large_area_name']] = True
            ken_dict[row['ken_name']] = True
            small_area_dict[row['small_area_name']] = True

    return genre_dict, large_area_dict, ken_dict, small_area_dict


def convert_int(value):
    if value == 'NA':
        return 0
    else:
        return int(value)

def coupon_row_to_vector(row, genre_dict, large_area_dict, ken_dict, small_area_dict):
    vector = []

    for genre in genre_dict:
        if row['GENRE_NAME'] == genre:
            vector.append(1)
        else:
            vector.append(0)

    vector.append(int(row['PRICE_RATE']))
    vector.append(int(row['CATALOG_PRICE']))
    vector.append(int(row['DISCOUNT_PRICE']))

    vector.append(convert_int(row['DISPPERIOD']))
    vector.append(convert_int(row['VALIDPERIOD']))


    vector.append(convert_int(row['USABLE_DATE_MON']))
    vector.append(convert_int(row['USABLE_DATE_TUE']))
    vector.append(convert_int(row['USABLE_DATE_WED']))
    vector.append(convert_int(row['USABLE_DATE_THU']))
    vector.append(convert_int(row['USABLE_DATE_FRI']))
    vector.append(convert_int(row['USABLE_DATE_SAT']))
    vector.append(convert_int(row['USABLE_DATE_SUN']))
    vector.append(convert_int(row['USABLE_DATE_HOLIDAY']))
    vector.append(convert_int(row['USABLE_DATE_BEFORE_HOLIDAY']))

    # use small area name only
    # for small_area in small_area_dict:
    #     if row['small_area_name'] == small_area:
    #         vector.append(1)
    #     else:
    #         vector.append(0)

    for ken in ken_dict:
        if row['ken_name'] == ken:
            vector.append(1)
        else:
            vector.append(0)

    return vector



def compose_coupon_hash_to_vector_dict(coupon_list):
    coupon_hash_to_vector_dict = {}
    coupon_hash_to_pref = {}

    genre_dict, large_area_dict, ken_dict, small_area_dict = get_info_from_coupon_list()

    with open(coupon_list, 'r') as csvfile:
        spamreader = csv.DictReader(csvfile)
        for row in spamreader:

            vector = coupon_row_to_vector(row, genre_dict, large_area_dict, ken_dict, small_area_dict)

            coupon_hash_to_pref[row['COUPON_ID_hash']] = row['ken_name']

            coupon_hash_to_vector_dict[row['COUPON_ID_hash']] = vector





    return coupon_hash_to_vector_dict, coupon_hash_to_pref

def compose_train_data(coupon_detail_train, user_hash_to_vector_dict, train_coupon_hash_to_vector_dict):
    user_hash_to_coupon_list = {}


    with open(coupon_detail_train, 'r') as csvfile:
        spamreader = csv.DictReader(csvfile)
        for row in spamreader:
            user_hash = row['USER_ID_hash']
            coupon_hash = row['COUPON_ID_hash']

            if user_hash not in user_hash_to_coupon_list:
                user_hash_to_coupon_list[user_hash] = []

            user_hash_to_coupon_list[user_hash].append(coupon_hash)




    return user_hash_to_coupon_list

def average_cosine_distance(user_hash, coupon_vector, train_coupon_hash_to_vector_dict, user_hash_to_train_coupon_list):
    train_coupon_list = user_hash_to_train_coupon_list[user_hash]

    if len(train_coupon_list) == 0:
        return 1.0

    sum_cosine_distance = 0.0
    train_coupon_list = user_hash_to_train_coupon_list[user_hash]

    for coupon_hash in train_coupon_list:
        sum_cosine_distance += cosine(coupon_vector, train_coupon_hash_to_vector_dict[coupon_hash])


    return sum_cosine_distance/len(train_coupon_list)





def main():
    user_list = './data/user_list.csv'
    user_hash_to_vector_dict, user_hash_to_pref = compose_user_hash_to_vector_dict(user_list)

    coupon_list_train = './data/coupon_list_train.csv'
    train_coupon_hash_to_vector_dict, train_coupon_hash_to_pref = compose_coupon_hash_to_vector_dict(coupon_list_train)

    coupon_detail_train = './data/coupon_detail_train.csv'
    user_hash_to_train_coupon_list = compose_train_data(coupon_detail_train, user_hash_to_vector_dict, train_coupon_hash_to_vector_dict)

    coupon_list_test = './data/coupon_list_test.csv'
    user_hash_to_coupon_average_cosine_distance = {}
    for user_hash in user_hash_to_train_coupon_list:
        user_hash_to_coupon_average_cosine_distance[user_hash] = {}





    genre_dict, large_area_dict, ken_dict, small_area_dict = get_info_from_coupon_list()
    with open(coupon_list_test, 'r') as csvfile:
        spamreader = csv.DictReader(csvfile)
        for row in spamreader:
            coupon_vector = coupon_row_to_vector(row, genre_dict, large_area_dict, ken_dict, small_area_dict)

            coupon_hash = row['COUPON_ID_hash']

            for user_hash in user_hash_to_coupon_average_cosine_distance:
                user_hash_to_coupon_average_cosine_distance[user_hash][coupon_hash] = average_cosine_distance(user_hash, coupon_vector, train_coupon_hash_to_vector_dict, user_hash_to_train_coupon_list)





    for user_hash in user_hash_to_coupon_average_cosine_distance:
        user_hash_to_coupon_average_cosine_distance[user_hash] = sorted(user_hash_to_coupon_average_cosine_distance[user_hash].items(), key=operator.itemgetter(1))



    threshold = 15


    print 'writing answer...'
    with open('prediction.csv', 'w') as w:
        w.write('USER_ID_hash,PURCHASED_COUPONS\n')
        for user_hash in user_hash_to_vector_dict:
            w.write(user_hash + ',')

            index = 0
            while index < len(user_hash_to_coupon_average_cosine_distance[user]) and index < threshold:
                w.write(user_hash_to_coupon_average_cosine_distance[user][index][0] + ' ')
                index += 1

            w.write('\n')






if __name__ == '__main__':
    main()
