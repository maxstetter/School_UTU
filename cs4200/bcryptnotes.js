app.post('/users', (req, res) =>{
    console.log("raw request body: ", req.body);
    var user = new User({
        fname: req.body.fname,
        lname: req.body.lname,
        email: req.body.email
    });
    //Method on the user.
    user.setEncryptedPassword(req.body.password).then(function () {
        //promise has now been fulfilled. 
        user.save().then(()=> {
            res.status(201).send("User created.")
        }).catch((error)=> {
            if (error.code == 11000){
                //email is not unique.
            }
            console.error("Error occured while creating a user.", error)
            if(error.errors){
                errors = {};
                for (let e in error.errors){
                    errorMessages[e] = error.errors[e].message;
                }
                res.status(422).json(errorMessages);
            } else {
                res.status(500).send("Server Error!")
            }
        });
    });
})


////////////////MODEL STUFF
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
	fname: {
		type: String,
		required: [true, "First name is required."]
	},
	lname: {
		type: String,
		required: [true, "Last name is required."]
	},
	email: {
		type: String,
		required: [true, "email is required."],
        unique: true
	},
	encryptedPassword: {
		type: String,
		required: [true, "password is required."]
	}
});

userSchema.methods.setEncryptedPassword = function (plainPassword) {
    //Creating a promise and returning. A promise is an object that is a carrier for something to come in the future.
    // An empty envelope that eventually will have something in it. 
    let promise = new Promise((resolve, reject) => {
        //applies to "this" model instance. 
        //TODO: encrypt plainPassword and set on the model instance.
        // hash => because you cannot use 'this' inside of the function.
        bcrypt.hash(myPlaintextPassword, 12).then(hash => {
            //store hash in your password debug.
            this.encryptedPassword = hash;
            //resolve the promise here.
            resolve();
        });
    });
    
    return promise;
};


userSchema.methods.verifyPassword = function (plainPassword) {
    let promise = new Promise((resolve, reject) => {
        bcrypt.compare(plainPassword, this.encryptedPassword).then(result => {
            resolve(result);
        });
    });
    return promise;
}
const User = mongoose.model('User', userSchema);

//////////////////////PASSPORT STUFF////////////////////////////////


//INSIDE OF INDEX.JS
const passport = require('passport')
const session = require('express-session')

const passportLocal = require('passport-local')

app.use(session({ secret: 'asdf1qaz2wsxhigrug9', resave: false, saveUninitialized: true }));
app.use(passport.initialize());
app.use(passport.session());

passport.use(new passportLocal.Strategy({
   usernameField: 'email',
   passwordField: 'plainPassword' 
    }, function (email, plainPassword, done) {
      //Authentication logic goes here
      //call done when you have an answer from your own function.
      
      //1 - check if the user exists in the DB by email.
      User.findOne({
          email: email
      }).then(function (user) {
            if (user) {
                //2 - if it does, verify the password using bcrypt
                user.verifyPassword(plainPassword).then(function (result) {
                    if (result) {
                        done(user, false);
                    } else {
                        done(null, false);
                    }
                });
          } else { 
              done(null, false);
          }
      })//.catch(function (err) {
            //handle error here.  
//            done(err);
//      });
      //3 - respond accordingly via the done() function.
    }));

passport.serializeUser( function (user, done) {
    done(null, user._id);
});

passport.deserializeUser( function (userId, done) {
    User.findOne({ _id: userId }).then( function (user) {
        done(null, user);
    }).catch(function (err) {
        done(err);
    });
});

app.post('/session', passport.authenticate('local'), function (req, res) {
    console.log("authentication succeeded.")
    res.sendStatus(201);
});

app.get('/me', function (req, res) {
    if (req.user) {
        res.json(req.user);
    } else {
        res.sendStatus(401);
    }
});

//This can be put in a helper function.    
    if(!req.user){
        res.sendStatus(401);
        return;
    }

function authenticate(){
    if(!req.user){
        res.sendStatus(401);
        return false;
    }
    return true;
}
//
app.get('/students', (req, res) => {
    if(!req.user){
        res.sendStatus(401);
        return;
    }else {
        Student.find().then((students) => {
            res.json(students);
        });
    }
})

//TODO: Do not forget to add credentials: "include"
//goes into method body Headers.