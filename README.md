![GitHub Logo](logo.png)

**ReflektorKit** is a stylesheet engine for iOS compatible with Objective-C and Swift on iOS8+.

##Getting started

- TODO


##Stylesheet

```css

//Right-hand side supported values
trait:rhs
{
	!include: trait:otherTrait, class:aClass;
	!condition: 'idiom = pad and width < 200 and vertical = regular';
    color-one: #00ff00;
    color-two: rgb(255, 0, 0);
    color-three: rgba(255, 0, 0, 0.3);
    color-four: hsl(120, 100%, 75%);
    color-five: hsla(120, 60%, 70%, 0.3);
    font: uifont('Arial', 16pt);
    font-two: uifont('Arial', 50%);
    number: 23.4px;
    percent: 50%;
    bool-one: true;
    bool-two: false;
    string: 'A string';
    rect: cgrect(0px, 0px, 100px, 200px);
    point: cgpoint(100px, 200px);
    size: cgsize(123px, 456px);
    edge: uiedgeinsets(1px, 2px, 3px, 4px);
    text: nslocalized('KEY');
    vector: vector(2px, 23px, #bbbbbb, #cccccc);
}


```
