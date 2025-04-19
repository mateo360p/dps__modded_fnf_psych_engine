package states.stages;

class SchoolEvilAlt extends SchoolEvil {
    override function create() {
        this.isAlt = true;

        super.create(); //yup, that's it
    }
}