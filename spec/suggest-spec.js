describe("Experiment.suggest", function() {
  var testUuid = "45923780-80ed-47c6-aa46-15e2ae7a0e8c";
  var experiment;

  beforeEach(function() {
    experiment = new Experiment(testUuid);
  })

  it("should return a suggestion when asked to", function() {
    var flag = false;
    var result = false;

    runs(function () {
      experiment.suggest(
        function(suggestion) { flag = true; result = suggestion },
        function(error) { flag = true; result = error})
    })

    waitsFor(function() { return flag; }, "The suggestion should return", 500)

    runs(function() {
      expect(result.choice).toBeTruthy();
      expect(result.token).toBeTruthy();
    })
  })

  it("should handle errors on an invalid UUID", function() {
    var flag = false;
    var result = false;

    runs(function () {
      new Experiment("br0ken").suggest(
        function(suggestion) { flag = true; result = suggestion },
        function(error) { flag = true; result = error})
    })

    waitsFor(function() { return flag; }, "the suggestion to return", 500)

    runs(function() {
      console.log(result)
      expect(result.typename).toBe('problem');
      expect(result.subtype).toBe(400);
      expect(result.messages).toBeTruthy();
    })
  })

  it("should handle timeouts when the server doesn't respond", function() {
    var flag = false;
    var result = false;

    runs(function () {
      new Experiment("br0ken", {baseurl: "http://example.com/"}).suggest(
        function(suggestion) { flag = true; result = suggestion },
        function(error) { flag = true; result = error})
    })

    waitsFor(function() { return flag; }, "the suggestion to return", 500)

    runs(function() {
      console.log(result)
      expect(result.typename).toBe('problem');
      expect(result.subtype).toBe(500);
      expect(result.messages).toBeTruthy();
      expect(result.messages[0].typename).toBe('timeout')
    })
  })
})
