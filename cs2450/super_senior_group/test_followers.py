import os
from selenium import webdriver
import time
import tinydb
import unittest

from db import posts
from db import users

class TestFollowButton(unittest.TestCase):

    def setUp(self):
        self.filename = '/tmp/youfacetestdb'+str(time.time())
        self.db = tinydb.TinyDB(self.filename)

        self.username = "username"

        # create user
        users = self.db.table('users')
        user_record = {
                'username': self.username,
                'password': self.username,
                'friends': []
                }
        users.insert(user_record)

        # create post
        users_table = self.db.table('users')
        self.user = {"user": self.username, "text": "asdf", "likers": []}
        self.username = users_table.insert(self.username)

        # 'user': user['username'],
        # 'text': text,
        # 'time': time.time()
        # 'likers': []


    ''' 
    Test if a new friend can be added. If works then new friend count
    should increase by one. 
    '''
    @unittest.skip("Not concerned about this right now")
    def test_database_function(self):
        # when called on a post, # of friends should increase
        users_table = self.db.table('users')
        original_count = len(users_table.get(doc_id=self.username)['friends'])
        users.add_user_friend(self.db, 'asdf', self.username)

        new_count = len(users_table.get(doc_id=self.username)['friends'])

        self.assertNotEqual(original_count, new_count, "You have no friends.")
        self.assertEqual(original_count+1, new_count)


    # Test if Friend button is working 
    '''
    Test if the friend button is working. It first logs you in and then 
    it finds the add friend button and adds a friend named
    asdf. 
    '''
    def test_friend_button(self):
        driver = webdriver.Chrome(executable_path="./tests/chromedriver")
        # TODO: don't forget proto
        driver.add_cookie({"name": "username", "value": self.username})
        driver.add_cookie({"name": "password", "value": 'asdf'})
        driver.get("http://localhost:5000")
        self.assertEqual("YouFace 2.0", driver.title, "Make sure the title is correct")
        login_btn = driver.find_element_by_class_name("btn-primary")
        self.assertEqual(login_btn.get_attribute("value"), "Login")
        username_field = driver.find_element_by_class_name("btn-primary")
        self.assertEqual(username_field.get_attribute("value"), self.username)
        password_field = driver.find_element_by_class_name("btn-primary")
        self.assertEqual(password_field.get_attribute("value"), 'asdf')
        friend_btn = driver.find_element_by_class_name("btn-primary")
        self.assertEqual(friend_btn.get_attribute("value"), "Friend")
        # 1. find username box
        # 2. enter username into the box (e.g., text_field.send_keys(self.username))
        # 3. do same for password
        login_btn.click()
        friend_btn.click()
        alerts = driver.find_element_by_class_name("alert")
        self.assertEqual(len(alerts), 1)
        driver.close()

    '''
    Test delete friend counts the users current friend count. It then
    searches for a friend named asdf and removes that user as a friend.
    It compares the original count of friends to the new count. If it is one less
    then it considers it to have worked.
    '''
    def test_delete_friend(self):
        # when called on a post, # of friends should increase
        users_table = self.db.table('users')
        original_count = len(users_table.get(doc_id=self.username)['friends'])
        users.remove_user_friend(self.db, 'asdf', self.username)

        new_count = len(users_table.get(doc_id=self.username)['friends'])

        self.assertNotEqual(original_count, new_count, "You are still friends.")
        self.assertEqual(original_count-1, new_count)



    def tearDown(self):
        self.db.close()
        os.remove(self.filename)
