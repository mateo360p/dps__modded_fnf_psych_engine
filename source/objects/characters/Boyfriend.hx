package objects.characters;

class Boyfriend extends BaseCharacter {
    public function new(_char:Character) {
        super(_char);
        this.fakeOutAssets = {char: "bf-fakeout", sound: "death/fakeout_death"};
        this.fakeOutProb = 4096; // huh
    }
}